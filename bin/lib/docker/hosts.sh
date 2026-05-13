DOCKER_HOSTS_ENTRY_ADDED=0

hosts_entry_exists() {
  local entry=$1
  grep -qxF "$entry" /etc/hosts
}

add_hosts_entry() {
  local entry=$1

  DOCKER_HOSTS_ENTRY_ADDED=0

  [[ -n "$entry" ]] || return 0

  if hosts_entry_exists "$entry"; then
    return 0
  fi

  printf '%s\n' "$entry" | sudo tee -a /etc/hosts > /dev/null || return 1
  DOCKER_HOSTS_ENTRY_ADDED=1
  return 0
}

remove_hosts_entry() {
  local entry=$1
  local temp_file
  local grep_status

  [[ -n "$entry" ]] || return 0

  if ! hosts_entry_exists "$entry"; then
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
