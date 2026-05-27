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
