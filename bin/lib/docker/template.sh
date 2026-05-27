set_substitution() {
  local substitutions_name=$1
  local key=$2
  local value=$3
  local -n substitutions_ref=$substitutions_name

  substitutions_ref["$key"]=$value
}

should_preserve_file() {
  local preserve_name=$1
  local relative_path=$2
  local preserved_path
  local -n preserve_ref=$preserve_name

  for preserved_path in "${preserve_ref[@]}"; do
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
  local substitutions_name=$3
  local key
  local value
  local escaped_value
  local -a sed_args=()
  local -n substitutions_ref=$substitutions_name

  for key in "${!substitutions_ref[@]}"; do
    value=${substitutions_ref[$key]}
    escaped_value=$(escape_sed_replacement "$value")
    sed_args+=(-e "s|@$key@|$escaped_value|g")
  done

  if ((${#sed_args[@]} == 0)); then
    cat "$source_file" >"$destination_file"
    return 0
  fi

  sed "${sed_args[@]}" "$source_file" >"$destination_file"
}

prepare_stage_dir() {
  local service_name=$1
  local template_name=$2
  local data_name=$3
  local preserve_name=$4
  local stage_dir
  local source_relative
  local destination_relative
  local source_file
  local stage_file
  local final_file
  local data_dir
  local -n service_ref=$service_name
  local -n template_ref=$template_name
  local -n data_ref=$data_name
  local -A substitutions=()

  stage_dir=$(mktemp -d) || return 1

  if [[ -n "${service_ref["prepare_stage_hook"]}" ]]; then
    if ! "${service_ref["prepare_stage_hook"]}" "$service_name" substitutions; then
      rm -rf "$stage_dir"
      return 1
    fi
  fi

  for data_dir in "${data_ref[@]}"; do
    mkdir -p "$stage_dir/$data_dir" || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  for template_mapping in "${template_ref[@]}"; do
    source_relative=${template_mapping%%:*}
    destination_relative=${template_mapping#*:}
    source_file="${service_ref["template_dir"]}/$source_relative"
    stage_file="$stage_dir/$destination_relative"
    final_file="${service_ref["install_dir"]}/$destination_relative"

    mkdir -p "$(dirname "$stage_file")" || {
      rm -rf "$stage_dir"
      return 1
    }

    if should_preserve_file "$preserve_name" "$destination_relative" && [[ -f "$final_file" ]]; then
      cp "$final_file" "$stage_file" || {
        rm -rf "$stage_dir"
        return 1
      }
      continue
    fi

    render_template "$source_file" "$stage_file" substitutions || {
      rm -rf "$stage_dir"
      return 1
    }
  done

  printf '%s\n' "$stage_dir"
}
