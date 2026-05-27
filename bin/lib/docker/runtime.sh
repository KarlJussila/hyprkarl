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
