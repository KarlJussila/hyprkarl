# bin/lib/docker.sh
# Manage local Docker service stacks. Sourced by hk-docker,
# hk-menu-docker-install, hk-menu-docker-uninstall.
#
# Module-level globals hold "the currently-loaded service" — populated by
# load_service, consumed by every other function. This lets callers do:
#
#   load_service "$service_id" || return 1
#   install_loaded_service
#
# without passing structs around by nameref.

DOCKER_SERVICE_ROOT="$HYPRKARL_PATH/templates/docker/services"
DOCKER_CONTAINERS_DIR="$HOME/.docker-containers"

declare -A DOCKER_SERVICE=()
declare -a DOCKER_TEMPLATE_FILES=()
declare -a DOCKER_DATA_DIRS=()
declare -a DOCKER_PRESERVE_FILES=()
declare -A DOCKER_SUBSTITUTIONS=()

# --- /etc/hosts entries ---

add_hosts_entry() {
  local entry=$1

  [[ -n "$entry" ]] || return 0

  if grep -qxF "$entry" /etc/hosts; then
    return 0
  fi

  printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null
}

remove_hosts_entry() {
  local entry=$1
  local temp_file

  [[ -n "$entry" ]] || return 0

  if ! grep -qxF "$entry" /etc/hosts; then
    return 0
  fi

  temp_file=$(mktemp) || return 1

  grep -vxF "$entry" /etc/hosts >"$temp_file"
  if [[ $? -gt 1 ]]; then
    rm -f "$temp_file"
    return 1
  fi

  if ! sudo install -m 0644 "$temp_file" /etc/hosts; then
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"
}

# --- manifest registry ---

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

# Read a service manifest and populate DOCKER_SERVICE / DOCKER_TEMPLATE_FILES /
# DOCKER_DATA_DIRS / DOCKER_PRESERVE_FILES. Source any per-service hooks.sh.
load_service() {
  local service_id=$1
  local service_dir="$DOCKER_SERVICE_ROOT/$service_id"
  local hooks_file="$service_dir/hooks.sh"
  local manifest
  local key
  local value

  manifest=$(manifest_path "$service_id")

  if [[ ! -f "$manifest" ]]; then
    gum log --level error "Unknown Docker service: $service_id"
    return 1
  fi

  if ! jq -e '
    type == "object"
    and (.id | type == "string" and length > 0)
    and (.label | type == "string" and length > 0)
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
  ' "$manifest" >/dev/null; then
    gum log --level error "Invalid Docker service manifest: $manifest"
    return 1
  fi

  DOCKER_SERVICE=()
  DOCKER_TEMPLATE_FILES=()
  DOCKER_DATA_DIRS=()
  DOCKER_PRESERVE_FILES=()

  while IFS=$'\t' read -r key value; do
    DOCKER_SERVICE["$key"]=$(expand_manifest_value "$value")
  done < <(
    jq -r '
      {
        id,
        label,
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
    ' "$manifest"
  )

  DOCKER_SERVICE["install_dir"]="$DOCKER_CONTAINERS_DIR/$service_id"
  DOCKER_SERVICE["template_dir"]="$service_dir"

  if [[ "${DOCKER_SERVICE["id"]}" != "$service_id" ]]; then
    gum log --level error "Docker service manifest id mismatch for $service_id"
    return 1
  fi

  mapfile -t DOCKER_TEMPLATE_FILES  < <(jq -r '.template_files[]?'  "$manifest")
  mapfile -t DOCKER_DATA_DIRS       < <(jq -r '.data_dirs[]?'       "$manifest")
  mapfile -t DOCKER_PRESERVE_FILES  < <(jq -r '.preserve_files[]?'  "$manifest")

  if [[ -f "$hooks_file" ]]; then
    source "$hooks_file"
  fi
}

# Filter is one of: all, installed, missing.
list_services() {
  local filter=$1
  local service_id

  case "$filter" in
    all|installed|missing) ;;
    *)
      gum log --level error "Unknown Docker service filter: $filter"
      return 1
      ;;
  esac

  while IFS= read -r service_id; do
    load_service "$service_id" || return 1

    case "$filter" in
      installed)
        [[ -f "${DOCKER_SERVICE["install_dir"]}/${DOCKER_SERVICE["compose_file"]}" ]] || continue
        ;;
      missing)
        [[ -f "${DOCKER_SERVICE["install_dir"]}/${DOCKER_SERVICE["compose_file"]}" ]] && continue
        ;;
    esac

    printf '%s\t%s\n' "$service_id" "${DOCKER_SERVICE["label"]}"
  done < <(service_ids)
}

# --- docker compose runtime ---

ensure_network() {
  if docker network inspect traefik-proxy &>/dev/null; then
    return 0
  fi
  docker network create traefik-proxy
}

compose_up() {
  (
    cd "${DOCKER_SERVICE["install_dir"]}" || exit 1
    docker compose -f "${DOCKER_SERVICE["compose_file"]}" up -d
  )
}

compose_down() {
  (
    cd "${DOCKER_SERVICE["install_dir"]}" || exit 1
    docker compose -f "${DOCKER_SERVICE["compose_file"]}" down --rmi all --volumes
  )
}

# --- template rendering ---

# Helper for service hooks. Hooks call this to register substitutions that
# render_template will apply to all template files.
set_substitution() {
  DOCKER_SUBSTITUTIONS["$1"]=$2
}

should_preserve_file() {
  local relative_path=$1
  local preserved_path
  for preserved_path in "${DOCKER_PRESERVE_FILES[@]}"; do
    if [[ "$preserved_path" == "$relative_path" ]]; then
      return 0
    fi
  done
  return 1
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

render_template() {
  local source_file=$1
  local destination_file=$2
  local key
  local value
  local escaped_value
  local -a sed_args=()

  for key in "${!DOCKER_SUBSTITUTIONS[@]}"; do
    value=${DOCKER_SUBSTITUTIONS[$key]}
    escaped_value=$(escape_sed_replacement "$value")
    sed_args+=(-e "s|@$key@|$escaped_value|g")
  done

  if ((${#sed_args[@]} == 0)); then
    cat "$source_file" >"$destination_file"
    return 0
  fi

  sed "${sed_args[@]}" "$source_file" >"$destination_file"
}

# Build a staging directory under /tmp populated from the loaded service's
# templates, applying substitutions and copying preserved files in-place.
prepare_stage_dir() {
  local stage_dir
  local source_relative
  local destination_relative
  local source_file
  local stage_file
  local final_file
  local data_dir

  DOCKER_SUBSTITUTIONS=()

  stage_dir=$(mktemp -d) || return 1

  if [[ -n "${DOCKER_SERVICE["prepare_stage_hook"]}" ]]; then
    if ! "${DOCKER_SERVICE["prepare_stage_hook"]}"; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  for data_dir in "${DOCKER_DATA_DIRS[@]}"; do
    mkdir -p "$stage_dir/$data_dir" || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  for template_mapping in "${DOCKER_TEMPLATE_FILES[@]}"; do
    source_relative=${template_mapping%%:*}
    destination_relative=${template_mapping#*:}
    source_file="${DOCKER_SERVICE["template_dir"]}/$source_relative"
    stage_file="$stage_dir/$destination_relative"
    final_file="${DOCKER_SERVICE["install_dir"]}/$destination_relative"

    mkdir -p "$(dirname "$stage_file")" || {
      rm -rf "$stage_dir"
      return 1
    }

    if should_preserve_file "$destination_relative" && [[ -f "$final_file" ]]; then
      cp "$final_file" "$stage_file" || {
        rm -rf "$stage_dir"
        return 1
      }
      continue
    fi

    render_template "$source_file" "$stage_file" || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  printf '%s\n' "$stage_dir"
}

# --- install / uninstall workflow ---

validate_stage_dir() {
  local stage_dir=$1
  (
    cd "$stage_dir" || exit 1
    docker compose -f "${DOCKER_SERVICE["compose_file"]}" config -q
  )
}

install_stage_dir() {
  local stage_dir=$1
  local destination_relative
  local stage_file
  local destination_file
  local temp_file
  local data_dir

  mkdir -p "${DOCKER_SERVICE["install_dir"]}" || return 1

  for data_dir in "${DOCKER_DATA_DIRS[@]}"; do
    mkdir -p "${DOCKER_SERVICE["install_dir"]}/$data_dir" || return 1
  done

  for template_mapping in "${DOCKER_TEMPLATE_FILES[@]}"; do
    destination_relative=${template_mapping#*:}
    stage_file="$stage_dir/$destination_relative"
    destination_file="${DOCKER_SERVICE["install_dir"]}/$destination_relative"
    temp_file="$destination_file.tmp.$$"

    mkdir -p "$(dirname "$destination_file")" || return 1
    cp "$stage_file" "$temp_file" || return 1
    mv "$temp_file" "$destination_file" || return 1
  done
}

install_loaded_service() {
  local stage_dir

  gum log --level info "Preparing ${DOCKER_SERVICE["label"]} files..."
  stage_dir=$(prepare_stage_dir) || return 1

  gum log --level info "Validating ${DOCKER_SERVICE["label"]} compose file..."
  if ! validate_stage_dir "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if ((DOCKER_SERVICE["require_traefik_network"])); then
    gum log --level info "Ensuring traefik-proxy network exists..."
    if ! ensure_network; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Writing ${DOCKER_SERVICE["label"]} files..."
  if ! install_stage_dir "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if [[ -n "${DOCKER_SERVICE["hosts_entry"]}" ]]; then
    gum log --level info "Adding /etc/hosts entry..."
    if ! add_hosts_entry "${DOCKER_SERVICE["hosts_entry"]}"; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Starting ${DOCKER_SERVICE["label"]}..."
  if ! compose_up; then
    remove_hosts_entry "${DOCKER_SERVICE["hosts_entry"]}"
    rm -rf "$stage_dir"
    return 1
  fi

  rm -rf "$stage_dir"

  if [[ -n "${DOCKER_SERVICE["install_message"]}" ]]; then
    gum log --level info "${DOCKER_SERVICE["install_message"]}"
  fi

  if [[ -n "${DOCKER_SERVICE["install_warning"]}" ]]; then
    gum log --level warn "${DOCKER_SERVICE["install_warning"]}"
  fi
}

remove_loaded_service() {
  if [[ "${DOCKER_SERVICE["install_dir"]}" != "$HOME/"* ]]; then
    gum log --level error "Refusing to remove Docker service files outside \$HOME: ${DOCKER_SERVICE["install_dir"]}"
    return 1
  fi

  if [[ ! -f "${DOCKER_SERVICE["install_dir"]}/${DOCKER_SERVICE["compose_file"]}" ]]; then
    gum log --level error "No ${DOCKER_SERVICE["label"]} installation found at ${DOCKER_SERVICE["install_dir"]}, nothing to do."
    return 0
  fi

  gum log --level warn "${DOCKER_SERVICE["remove_warning"]}"
  if ! gum confirm "Continue?"; then
    gum log --level error "Aborted."
    return 0
  fi

  gum log --level info "Stopping and removing ${DOCKER_SERVICE["label"]}..."
  compose_down || return 1

  if [[ -n "${DOCKER_SERVICE["hosts_entry"]}" ]]; then
    gum log --level info "Removing /etc/hosts entry..."
    remove_hosts_entry "${DOCKER_SERVICE["hosts_entry"]}" || return 1
  fi

  gum log --level info "Deleting ${DOCKER_SERVICE["install_dir"]}..."
  sudo rm -rf "${DOCKER_SERVICE["install_dir"]}" || return 1
}

docker_install_service() {
  local service_id=$1
  load_service "$service_id" || return 1
  install_loaded_service
}

docker_uninstall_service() {
  local service_id=$1
  load_service "$service_id" || return 1
  remove_loaded_service
}
