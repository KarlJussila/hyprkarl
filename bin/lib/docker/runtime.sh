
has_cli() {
  command -v docker &>/dev/null
}

has_compose() {
  docker compose version &>/dev/null
}

user_in_group() {
  id -nG "$USER" | grep -qw docker
}

docker_setup_complete() {
  has_cli \
    && has_compose \
    && user_in_group
}

require_cli() {
  if ! has_cli; then
    gum log --level error "Docker is not installed. Run hk-docker setup first."
    return 1
  fi

  if ! has_compose; then
    gum log --level error "Docker Compose is not available."
    return 1
  fi

  if ! user_in_group; then
    gum log --level error "User $USER is not in the docker group yet. Run hk-docker setup and restart the session."
    return 1
  fi

  if ! docker info &>/dev/null; then
    gum log --level error "Docker is installed but the daemon is not reachable. Make sure docker.service is running."
    return 1
  fi

  return 0
}

validate_install_dir() {
  local install_dir=$1

  case "$install_dir" in
    "")
      gum log --level error "Docker service install dir is empty."
      return 1
      ;;
    "$HOME")
      gum log --level error "Refusing to manage \$HOME directly for Docker service files."
      return 1
      ;;
    "$HOME"/*)
      return 0
      ;;
    *)
      gum log --level error "Refusing to manage Docker service files outside \$HOME: $install_dir"
      return 1
      ;;
  esac
}

docker_setup() {
  local -a packages=()

  pacman -Q docker &>/dev/null || packages+=(docker)
  pacman -Q docker-compose &>/dev/null || packages+=(docker-compose)

  if (( ${#packages[@]} > 0 )); then
    echo "Installing: ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi

  echo "Enabling docker.service..."
  sudo systemctl enable --now docker.service

  echo "Adding $USER to the docker group..."
  sudo usermod -aG docker "$USER"

  echo
  echo "Done. You must log out, log back in, or reboot before docker group membership takes effect."
  echo

  if gum confirm "Reboot now?"; then
    hk-reboot
  fi
}

ensure_network() {
  if docker network inspect traefik-proxy &>/dev/null; then
    return 0
  fi

  docker network create traefik-proxy
}

compose_up() {
  local service_name=$1
  local -n service_ref=$service_name

  (
    cd "${service_ref["install_dir"]}" || exit 1
    docker compose -f "${service_ref["compose_file"]}" up -d
  )
}

compose_down() {
  local service_name=$1
  local -n service_ref=$service_name

  (
    cd "${service_ref["install_dir"]}" || exit 1
    docker compose -f "${service_ref["compose_file"]}" down --rmi all --volumes
  )
}
