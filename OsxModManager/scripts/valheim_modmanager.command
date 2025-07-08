#!/usr/bin/env bash

chmod +x "$(dirname "$0")/valheim_dep_manager.sh"

# Forward all arguments to the real script
"$(dirname "$0")/mod_manager.sh" "$@"
