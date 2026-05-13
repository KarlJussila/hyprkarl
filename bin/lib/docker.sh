SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/shell.sh"
source "$SCRIPT_DIR/docker/registry.sh"
source "$SCRIPT_DIR/docker/hosts.sh"
source "$SCRIPT_DIR/docker/template.sh"
source "$SCRIPT_DIR/docker/runtime.sh"
source "$SCRIPT_DIR/docker/workflow.sh"
