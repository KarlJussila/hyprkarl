searxng_prepare_stage() {
  local secret
  secret=$(openssl rand -hex 32) || return 1
  set_substitution "SEARXNG_SECRET" "$secret"
}
