
DOCKER_SERVICE_ROOT="$HYPRKARL_PATH/templates/docker/services"

service_ids() {
  find "$DOCKER_SERVICE_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

manifest_path() {
  printf '%s/%s/service.json\n' "$DOCKER_SERVICE_ROOT" "$1"
}

expand_manifest_value() {
  local value=$1

  value=${value//\$\{HOME\}/$HOME}
  value=${value//\$HOME/$HOME}

  printf '%s' "$value"
}

require_manifest_parser() {
  if command -v jq &>/dev/null; then
    return 0
  fi

  gum log --level error "jq is required to parse Docker service manifests."
  return 1
}

load_service() {
  local service_id=$1
  local service_name=$2
  local template_name=$3
  local data_name=$4
  local preserve_name=$5
  local service_dir="$DOCKER_SERVICE_ROOT/$service_id"
  local manifest_path
  local hooks_file="$service_dir/hooks.sh"
  local key
  local value
  local -n service_ref=$service_name
  local -n template_ref=$template_name
  local -n data_ref=$data_name
  local -n preserve_ref=$preserve_name

  manifest_path=$(manifest_path "$service_id")

  require_manifest_parser || return 1

  if [[ ! -f "$manifest_path" ]]; then
    gum log --level error "Unknown Docker service: $service_id"
    return 1
  fi

  if ! jq -e '
    type == "object"
    and (.id | type == "string" and length > 0)
    and (.label | type == "string" and length > 0)
    and (.install_dir | type == "string" and length > 0)
    and (.compose_file | type == "string" and length > 0)
    and (.template_files | type == "array")
    and (.template_files | all(.[]; type == "string"))
    and ((.data_dirs // []) | type == "array")
    and ((.data_dirs // []) | all(.[]; type == "string"))
    and ((.preserve_files // []) | type == "array")
    and ((.preserve_files // []) | all(.[]; type == "string"))
    and ((.hosts_entry // "") | type == "string")
    and ((.install_message // "") | type == "string")
    and ((.install_warning // "") | type == "string")
    and ((.remove_warning // "") | type == "string")
    and ((.prepare_stage_hook // "") | type == "string")
    and ((.require_traefik_network // false) | type == "boolean")
  ' "$manifest_path" > /dev/null; then
    gum log --level error "Invalid Docker service manifest: $manifest_path"
    return 1
  fi

  service_ref=()
  template_ref=()
  data_ref=()
  preserve_ref=()

  while IFS=$'\t' read -r key value; do
    service_ref["$key"]=$(expand_manifest_value "$value")
  done < <(
    jq -r '
      {
        id,
        label,
        install_dir,
        compose_file,
        hosts_entry: (.hosts_entry // ""),
        require_traefik_network: (if (.require_traefik_network // false) then "1" else "0" end),
        install_message: (.install_message // ""),
        install_warning: (.install_warning // ""),
        remove_warning: (.remove_warning // ""),
        prepare_stage_hook: (.prepare_stage_hook // "")
      }
      | to_entries[]
      | [.key, (.value | tostring)]
      | @tsv
    ' "$manifest_path"
  )

  if [[ "${service_ref["id"]}" != "$service_id" ]]; then
    gum log --level error "Docker service manifest id mismatch for $service_id"
    return 1
  fi

  service_ref["template_dir"]="$service_dir"

  mapfile -t template_ref < <(jq -r '.template_files[]?' "$manifest_path")
  mapfile -t data_ref < <(jq -r '.data_dirs[]?' "$manifest_path")
  mapfile -t preserve_ref < <(jq -r '.preserve_files[]?' "$manifest_path")

  if [[ -f "$hooks_file" ]]; then
    source "$hooks_file"
  fi

  return 0
}

compose_path() {
  local service_name=$1
  local -n service_ref=$service_name

  printf '%s/%s\n' \
    "${service_ref["install_dir"]}" \
    "${service_ref["compose_file"]}"
}

service_installed() {
  local service_name=$1

  [[ -f "$(compose_path "$service_name")" ]]
}

list_services() {
  local filter=$1
  local service_id
  local installed=0
  local -A service=()
  local -a template_files=()
  local -a data_dirs=()
  local -a preserve_files=()

  case "$filter" in
    all|installed|missing) ;;
    *)
      gum log --level error "Unknown Docker service filter: $filter"
      return 1
      ;;
  esac

  while IFS= read -r service_id; do
    load_service "$service_id" service template_files data_dirs preserve_files || return 1

    installed=0
    if service_installed service; then
      installed=1
    fi

    case "$filter" in
      installed)
        (( installed )) || continue
        ;;
      missing)
        (( installed )) && continue
        ;;
    esac

    printf '%s\t%s\n' "$service_id" "${service["label"]}"
  done < <(service_ids)
}

docker_list_services() {
  list_services "$@"
}
