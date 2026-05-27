SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/registry.sh"
source "$SCRIPT_DIR/hosts.sh"
source "$SCRIPT_DIR/template.sh"
source "$SCRIPT_DIR/runtime.sh"
source "$SCRIPT_DIR/workflow.sh"
