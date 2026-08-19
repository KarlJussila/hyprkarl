# bin/lib/fingerprint.sh
# Shared fingerprint names, labels, and setup-state detection.

FINGERPRINT_NAMES=(
  "left-thumb"
  "left-index-finger"
  "left-middle-finger"
  "left-ring-finger"
  "left-little-finger"
  "right-thumb"
  "right-index-finger"
  "right-middle-finger"
  "right-ring-finger"
  "right-little-finger"
)

fingerprint_is_setup() {
  command -v fprintd-list &>/dev/null \
    && grep -q pam_fprintd.so /etc/pam.d/sudo 2>/dev/null
}

fingerprint_label() {
  sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g' <<<"$1"
}
