searxng_prepare_stage() {
  local service_name=$1
  local substitutions_name=$2
  local secret

  [[ -n "$service_name" ]] || return 1
  secret=$(openssl rand -hex 32) || return 1
  set_substitution "$substitutions_name" "SEARXNG_SECRET" "$secret"
}
