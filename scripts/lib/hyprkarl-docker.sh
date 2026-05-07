SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./hyprkarl-shell.sh
source "$SCRIPT_DIR/hyprkarl-shell.sh"

HYPRKARL_DOCKER_SERVICE_ROOT="$HYPRKARL_PATH/templates/docker/services"
HYPRKARL_DOCKER_SERVICE_IDS=(degoog searxng kiwix traefik)
HYPRKARL_DOCKER_HOSTS_ENTRY_ADDED=0

hyprkarl_docker_reset_service() {
  HYPRKARL_DOCKER_SERVICE_ID=""
  HYPRKARL_DOCKER_SERVICE_LABEL=""
  HYPRKARL_DOCKER_SERVICE_INSTALL_DIR=""
  HYPRKARL_DOCKER_SERVICE_COMPOSE_FILE=""
  HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY=""
  HYPRKARL_DOCKER_SERVICE_REQUIRE_TRAEFIK_NETWORK=0
  HYPRKARL_DOCKER_SERVICE_INSTALL_MESSAGE=""
  HYPRKARL_DOCKER_SERVICE_INSTALL_WARNING=""
  HYPRKARL_DOCKER_SERVICE_REMOVE_WARNING=""
  HYPRKARL_DOCKER_SERVICE_TEMPLATE_DIR=""
  HYPRKARL_DOCKER_SERVICE_TEMPLATE_FILES=()
  HYPRKARL_DOCKER_SERVICE_DATA_DIRS=()
  HYPRKARL_DOCKER_SERVICE_PRESERVE_FILES=()
}

hyprkarl_docker_service_ids() {
  printf '%s\n' "${HYPRKARL_DOCKER_SERVICE_IDS[@]}"
}

hyprkarl_docker_ready() {
  command -v docker &>/dev/null \
    && docker compose version &>/dev/null \
    && id -nG "$USER" | grep -qw docker
}

hyprkarl_docker_load_service() {
  local service_id=$1
  local service_file="$HYPRKARL_DOCKER_SERVICE_ROOT/$service_id/service.conf"

  hyprkarl_docker_reset_service

  if [[ ! -f "$service_file" ]]; then
    gum log --level error "Unknown Docker service: $service_id"
    return 1
  fi

  # shellcheck source=/dev/null
  source "$service_file"
  HYPRKARL_DOCKER_SERVICE_TEMPLATE_DIR="$HYPRKARL_DOCKER_SERVICE_ROOT/$service_id"
  return 0
}

hyprkarl_docker_compose_path() {
  printf '%s/%s\n' \
    "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR" \
    "$HYPRKARL_DOCKER_SERVICE_COMPOSE_FILE"
}

hyprkarl_docker_service_installed() {
  local service_id=$1

  hyprkarl_docker_load_service "$service_id" || return 1
  [[ -f "$(hyprkarl_docker_compose_path)" ]]
}

hyprkarl_docker_require_cli() {
  if ! command -v docker &>/dev/null; then
    gum log --level error "Docker is not installed. Run hyprkarl-docker-install first."
    return 1
  fi

  if ! docker compose version &>/dev/null; then
    gum log --level error "Docker Compose is not available."
    return 1
  fi

  if ! id -nG "$USER" | grep -qw docker; then
    gum log --level error "User $USER is not in the docker group yet. Run hyprkarl-docker-install and restart the session."
    return 1
  fi

  if ! docker info &>/dev/null; then
    gum log --level error "Docker is installed but the daemon is not reachable. Make sure docker.service is running."
    return 1
  fi

  return 0
}

hyprkarl_docker_ensure_network() {
  if docker network inspect traefik-proxy &>/dev/null; then
    return 0
  fi

  docker network create traefik-proxy
}

hyprkarl_docker_hosts_entry_exists() {
  local entry=$1
  grep -qxF "$entry" /etc/hosts
}

hyprkarl_docker_add_hosts_entry() {
  local entry=$1

  HYPRKARL_DOCKER_HOSTS_ENTRY_ADDED=0

  [[ -n "$entry" ]] || return 0

  if hyprkarl_docker_hosts_entry_exists "$entry"; then
    return 0
  fi

  printf '%s\n' "$entry" | sudo tee -a /etc/hosts > /dev/null || return 1
  HYPRKARL_DOCKER_HOSTS_ENTRY_ADDED=1
  return 0
}

hyprkarl_docker_remove_hosts_entry() {
  local entry=$1
  local temp_file
  local grep_status

  [[ -n "$entry" ]] || return 0

  if ! hyprkarl_docker_hosts_entry_exists "$entry"; then
    return 0
  fi

  temp_file=$(mktemp) || return 1

  grep -vxF "$entry" /etc/hosts > "$temp_file"
  grep_status=$?
  if [[ $grep_status -gt 1 ]]; then
    rm -f "$temp_file"
    return 1
  fi

  if ! sudo install -m 0644 "$temp_file" /etc/hosts; then
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"
  return 0
}

hyprkarl_docker_should_preserve_file() {
  local relative_path=$1
  local preserved_path

  for preserved_path in "${HYPRKARL_DOCKER_SERVICE_PRESERVE_FILES[@]}"; do
    if [[ "$preserved_path" == "$relative_path" ]]; then
      return 0
    fi
  done

  return 1
}

hyprkarl_docker_render_template() {
  local source_file=$1
  local destination_file=$2
  local searxng_secret=$3

  sed \
    -e "s|@SEARXNG_SECRET@|$searxng_secret|g" \
    "$source_file" > "$destination_file"
}

hyprkarl_docker_prepare_stage_dir() {
  local stage_dir
  local source_relative
  local destination_relative
  local source_file
  local stage_file
  local final_file
  local data_dir
  local searxng_secret=""

  stage_dir=$(mktemp -d) || return 1

  if [[ "$HYPRKARL_DOCKER_SERVICE_ID" == "searxng" ]]; then
    searxng_secret=$(openssl rand -hex 32) || {
      rm -rf "$stage_dir"
      return 1
    }
  fi

  for data_dir in "${HYPRKARL_DOCKER_SERVICE_DATA_DIRS[@]}"; do
    mkdir -p "$stage_dir/$data_dir" || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  for template_mapping in "${HYPRKARL_DOCKER_SERVICE_TEMPLATE_FILES[@]}"; do
    source_relative=${template_mapping%%:*}
    destination_relative=${template_mapping#*:}
    source_file="$HYPRKARL_DOCKER_SERVICE_TEMPLATE_DIR/$source_relative"
    stage_file="$stage_dir/$destination_relative"
    final_file="$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR/$destination_relative"

    mkdir -p "$(dirname "$stage_file")" || {
      rm -rf "$stage_dir"
      return 1
    }

    if hyprkarl_docker_should_preserve_file "$destination_relative" && [[ -f "$final_file" ]]; then
      cp "$final_file" "$stage_file" || {
        rm -rf "$stage_dir"
        return 1
      }
      continue
    fi

    hyprkarl_docker_render_template "$source_file" "$stage_file" "$searxng_secret" || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  printf '%s\n' "$stage_dir"
}

hyprkarl_docker_validate_stage_dir() {
  local stage_dir=$1

  (
    cd "$stage_dir" || exit 1
    docker compose -f "$HYPRKARL_DOCKER_SERVICE_COMPOSE_FILE" config -q
  )
}

hyprkarl_docker_install_stage_dir() {
  local stage_dir=$1
  local destination_relative
  local stage_file
  local destination_file
  local temp_file
  local data_dir

  mkdir -p "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR" || return 1

  for data_dir in "${HYPRKARL_DOCKER_SERVICE_DATA_DIRS[@]}"; do
    mkdir -p "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR/$data_dir" || return 1
  done

  for template_mapping in "${HYPRKARL_DOCKER_SERVICE_TEMPLATE_FILES[@]}"; do
    destination_relative=${template_mapping#*:}
    stage_file="$stage_dir/$destination_relative"
    destination_file="$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR/$destination_relative"
    temp_file="$destination_file.tmp.$$"

    mkdir -p "$(dirname "$destination_file")" || return 1
    cp "$stage_file" "$temp_file" || return 1
    mv "$temp_file" "$destination_file" || return 1
  done

  return 0
}

hyprkarl_docker_compose_up() {
  (
    cd "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR" || exit 1
    docker compose -f "$HYPRKARL_DOCKER_SERVICE_COMPOSE_FILE" up -d
  )
}

hyprkarl_docker_compose_down() {
  (
    cd "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR" || exit 1
    docker compose -f "$HYPRKARL_DOCKER_SERVICE_COMPOSE_FILE" down --rmi all --volumes
  )
}

hyprkarl_docker_install_loaded_service() {
  local stage_dir

  hyprkarl_docker_require_cli || return 1

  gum log --level info "Preparing ${HYPRKARL_DOCKER_SERVICE_LABEL} files..."
  stage_dir=$(hyprkarl_docker_prepare_stage_dir) || return 1

  gum log --level info "Validating ${HYPRKARL_DOCKER_SERVICE_LABEL} compose file..."
  if ! hyprkarl_docker_validate_stage_dir "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if (( HYPRKARL_DOCKER_SERVICE_REQUIRE_TRAEFIK_NETWORK )); then
    gum log --level info "Ensuring traefik-proxy network exists..."
    if ! hyprkarl_docker_ensure_network; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Writing ${HYPRKARL_DOCKER_SERVICE_LABEL} files..."
  if ! hyprkarl_docker_install_stage_dir "$stage_dir"; then
    rm -rf "$stage_dir"
    return 1
  fi

  if [[ -n "$HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY" ]]; then
    gum log --level info "Adding /etc/hosts entry..."
    if ! hyprkarl_docker_add_hosts_entry "$HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY"; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  gum log --level info "Starting ${HYPRKARL_DOCKER_SERVICE_LABEL}..."
  if ! hyprkarl_docker_compose_up; then
    if (( HYPRKARL_DOCKER_HOSTS_ENTRY_ADDED )); then
      hyprkarl_docker_remove_hosts_entry "$HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY"
    fi
    rm -rf "$stage_dir"
    return 1
  fi

  rm -rf "$stage_dir"

  if [[ -n "$HYPRKARL_DOCKER_SERVICE_INSTALL_MESSAGE" ]]; then
    gum log --level info "$HYPRKARL_DOCKER_SERVICE_INSTALL_MESSAGE"
  fi

  if [[ -n "$HYPRKARL_DOCKER_SERVICE_INSTALL_WARNING" ]]; then
    gum log --level warn "$HYPRKARL_DOCKER_SERVICE_INSTALL_WARNING"
  fi

  return 0
}

hyprkarl_docker_remove_loaded_service() {
  local compose_file

  compose_file=$(hyprkarl_docker_compose_path)
  if [[ ! -f "$compose_file" ]]; then
    gum log --level error "No ${HYPRKARL_DOCKER_SERVICE_LABEL} installation found at $HYPRKARL_DOCKER_SERVICE_INSTALL_DIR, nothing to do."
    return 0
  fi

  hyprkarl_docker_require_cli || return 1

  gum log --level warn "$HYPRKARL_DOCKER_SERVICE_REMOVE_WARNING"
  if ! gum confirm "Continue?"; then
    gum log --level error "Aborted."
    return 0
  fi

  gum log --level info "Stopping and removing ${HYPRKARL_DOCKER_SERVICE_LABEL}..."
  hyprkarl_docker_compose_down || return 1

  if [[ -n "$HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY" ]]; then
    gum log --level info "Removing /etc/hosts entry..."
    hyprkarl_docker_remove_hosts_entry "$HYPRKARL_DOCKER_SERVICE_HOSTS_ENTRY" || return 1
  fi

  gum log --level info "Deleting $HYPRKARL_DOCKER_SERVICE_INSTALL_DIR..."
  sudo rm -rf "$HYPRKARL_DOCKER_SERVICE_INSTALL_DIR" || return 1
  return 0
}

hyprkarl_docker_run_service_command() {
  local service_id=$1
  shift

  hyprkarl_docker_load_service "$service_id" || return 1

  case "$#" in
    0)
      hyprkarl_docker_install_loaded_service || return 1
      ;;
    1)
      if [[ "$1" != "--remove" ]]; then
        gum log --level error "Usage: hyprkarl-docker-$service_id [--remove]"
        return 1
      fi

      hyprkarl_docker_remove_loaded_service || return 1
      ;;
    *)
      gum log --level error "Usage: hyprkarl-docker-$service_id [--remove]"
      return 1
      ;;
  esac

  hyprkarl-show-done
}
