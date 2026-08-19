# bin/lib/keybindings.sh
# Read and format the live Hyprland keybinding registry.

format_pointer_buttons() {
  local line
  local code
  local symbol

  while IFS= read -r line; do
    if [[ "$line" =~ mouse:([0-9]+) ]]; then
      code="${BASH_REMATCH[1]}"

      case "$code" in
        272) symbol="LEFT MOUSE BUTTON" ;;
        273) symbol="RIGHT MOUSE BUTTON" ;;
        274) symbol="MIDDLE MOUSE BUTTON" ;;
        *) symbol="mouse:${code}" ;;
      esac

      echo "${line/mouse:${code}/$symbol}"
    else
      echo "$line"
    fi
  done
}

dynamic_bindings() {
  local bindings
  local formatted

  bindings=$(hyprctl -j binds) || return 1
  formatted=$(jq -r '
    if type != "array" then error("expected Hyprland binding array") else
      .[]
      | {modmask, key, keycode, description, dispatcher, arg}
      | "\(.modmask),\(.key)@\(.keycode),\(.description),\(.dispatcher),\(.arg)"
    end
  ' <<<"$bindings") || return 1

  sed -r \
      -e 's/null//' \
      -e 's,uwsm app -- ,,' \
      -e 's,uwsm-app -- ,,' \
      -e 's/@0//' \
      -e 's/,@/,code:/' \
      -e 's/^0,/,/' \
      -e 's/^1,/SHIFT,/' \
      -e 's/^4,/CTRL,/' \
      -e 's/^5,/SHIFT CTRL,/' \
      -e 's/^8,/ALT,/' \
      -e 's/^9,/SHIFT ALT,/' \
      -e 's/^12,/CTRL ALT,/' \
      -e 's/^13,/SHIFT CTRL ALT,/' \
      -e 's/^64,/SUPER,/' \
      -e 's/^65,/SUPER SHIFT,/' \
      -e 's/^68,/SUPER CTRL,/' \
      -e 's/^69,/SUPER SHIFT CTRL,/' \
      -e 's/^72,/SUPER ALT,/' \
      -e 's/^73,/SUPER SHIFT ALT,/' \
      -e 's/^76,/SUPER CTRL ALT,/' \
      -e 's/^77,/SUPER SHIFT CTRL ALT,/' \
    <<<"$formatted"
}

parse_bindings() {
  awk -F, '
  {
    key_combo = $1 " + " $2
    gsub(/^[ \t]*\+?[ \t]*/, "", key_combo)
    gsub(/[ \t]+$/, "", key_combo)

    action = $3
    if (action == "") {
      for (i = 4; i <= NF; i++) action = action $i (i < NF ? "," : "")
      sub(/,$/, "", action)
      gsub(/(^|,)[[:space:]]*exec[[:space:]]*,?/, "", action)
      gsub(/^[ \t]+|[ \t]+$/, "", action)
      gsub(/[ \t]+/, " ", key_combo)
    }

    if (action != "") printf "%-35s → %s\n", key_combo, action
  }'
}

prioritize_keybindings() {
  awk '
  {
    line = $0
    prio = 50
    if (match(line, /Terminal/)) prio = 1
    if (match(line, /Launch apps/)) prio = 3
    if (match(line, /Main menu/)) prio = 4
    if (match(line, /Browser/) && !match(line, /private/)) prio = 5
    if (match(line, /File manager/) && !match(line, /Alternative/)) prio = 7
    if (match(line, /Alternative file manager/)) prio = 8
    if (match(line, /Close window/)) prio = 9
    if (match(line, /Force kill window/)) prio = 10
    if (match(line, /Full screen/)) prio = 11
    if (match(line, /Toggle window floating/)) prio = 12
    if (match(line, /Toggle window split/)) prio = 13
    if (match(line, /Power menu/)) prio = 14
    if (match(line, /Wallpaper menu/)) prio = 15
    if (match(line, /Screenshot/)) prio = 16
    if (match(line, /notification/)) prio = 17
    if (match(line, /Switch to workspace/)) prio = 18
    if (match(line, /Move window to workspace/) && !match(line, /silently/)) prio = 20
    if (match(line, /Toggle scratchpad|Move window.*scratchpad/)) prio = 22
    if (match(line, /XF86/)) prio = 99
    if (match(line, /Lid Switch/)) prio = 99

    printf "%d\t%s\n", prio, line
  }' |
    sort -k1,1n -k2,2 |
    cut -f2-
}

keybindings_list() {
  local bindings

  bindings=$(dynamic_bindings) || return 1
  sort -u <<<"$bindings" |
    format_pointer_buttons |
    parse_bindings |
    prioritize_keybindings
}
