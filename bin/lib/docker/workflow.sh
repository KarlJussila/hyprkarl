
validate_stage_dir() {
  local service_name=$1
  local stage_dir=$2
  local -n service_ref=$service_name

  (
    cd "$stage_dir" || exit 1
    docker compose -f "${service_ref["compose_file"]}" config -q
  )
}

install_stage_dir() {
  local service_name=$1
  local template_name=$2
  local data_name=$3
  local stage_dir=$4
  local destination_relative
  local stage_file
  local destination_file
  local temp_file
  local data_dir
  local -n service_ref=$service_name
  local -n template_ref=$template_name
  local -n data_ref=$data_name

  mkdir -p "${service_ref["install_dir"]}" || return 1

  for data_dir in "${data_ref[@]}"; do
    mkdir -p "${service_ref["install_dir"]}/$data_dir" || return 1
  done

  for template_mapping in "${template_ref[@]}"; do
    destination_relative=${template_mapping#*:}
    stage_file="$stage_dir/$destination_relative"
    destination_file="${service_ref["install_dir"]}/$destination_relative"
    temp_file="$destination_file.tmp.$$"

    mkdir -p "$(dirname "$destination_file")" || return 1
    cp "$stage_file" "$temp_file" || return 1
    mv "$temp_file" "$destination_file" || return 1
  done

  return 0
}

install_loaded_service() {
  local service_name=$1
  local template_name=$2
  local data_name=$3
  local preserve_name=$4
  local stage_dir
  local -n service_ref=$service_name

  validate_install_dir "${service_ref["install_dir"]}" || return 1
  require_cli || return 1

  gum log --level info "Preparing ${service_ref["label"]} files..."
  stage_dir=$(prepare_stage_dir "$service_name" "$template_name" "$data_name" "$preserve_name") || return 1

  gum log --level info "Validating ${service_ref["label"]} compose file..."
  if ! validate_stage_dir "$service_name" "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if (( service_ref["require_traefik_network"] )); then
    gum log --level info "Ensuring traefik-proxy network exists..."
    if ! ensure_network; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Writing ${service_ref["label"]} files..."
  if ! install_stage_dir "$service_name" "$template_name" "$data_name" "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if [[ -n "${service_ref["hosts_entry"]}" ]]; then
    gum log --level info "Adding /etc/hosts entry..."
    if ! add_hosts_entry "${service_ref["hosts_entry"]}"; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Starting ${service_ref["label"]}..."
  if ! compose_up "$service_name"; then
    if (( DOCKER_HOSTS_ENTRY_ADDED )); then
      remove_hosts_entry "${service_ref["hosts_entry"]}"
    fi
    rm -rf "$stage_dir"
    return 1
  fi

  rm -rf "$stage_dir"

  if [[ -n "${service_ref["install_message"]}" ]]; then
    gum log --level info "${service_ref["install_message"]}"
  fi

  if [[ -n "${service_ref["install_warning"]}" ]]; then
    gum log --level warn "${service_ref["install_warning"]}"
  fi

  return 0
}

remove_loaded_service() {
  local service_name=$1
  local compose_file
  local -n service_ref=$service_name

  validate_install_dir "${service_ref["install_dir"]}" || return 1

  compose_file=$(compose_path "$service_name")
  if [[ ! -f "$compose_file" ]]; then
    gum log --level error "No ${service_ref["label"]} installation found at ${service_ref["install_dir"]}, nothing to do."
    return 0
  fi

  require_cli || return 1

  gum log --level warn "${service_ref["remove_warning"]}"
  if ! gum confirm "Continue?"; then
    gum log --level error "Aborted."
    return 0
  fi

  gum log --level info "Stopping and removing ${service_ref["label"]}..."
  compose_down "$service_name" || return 1

  if [[ -n "${service_ref["hosts_entry"]}" ]]; then
    gum log --level info "Removing /etc/hosts entry..."
    remove_hosts_entry "${service_ref["hosts_entry"]}" || return 1
  fi

  gum log --level info "Deleting ${service_ref["install_dir"]}..."
  sudo rm -rf "${service_ref["install_dir"]}" || return 1
  return 0
}

docker_install_service() {
  local service_id=$1
  local -A service=()
  local -a template_files=()
  local -a data_dirs=()
  local -a preserve_files=()

  load_service "$service_id" service template_files data_dirs preserve_files || return 1
  install_loaded_service service template_files data_dirs preserve_files
}

docker_uninstall_service() {
  local service_id=$1
  local -A service=()
  local -a template_files=()
  local -a data_dirs=()
  local -a preserve_files=()

  load_service "$service_id" service template_files data_dirs preserve_files || return 1
  remove_loaded_service service
}
