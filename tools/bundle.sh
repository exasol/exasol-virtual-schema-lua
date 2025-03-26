#!/bin/bash

# This script bundles the individual Lua modules into one file.

set -euo pipefail

if [[ -z "${1+x}" ]]
then
    script_dir=$(dirname "$(readlink -f "$0")") && readonly script_dir
    base_dir=$(readlink -f "$script_dir/..") && readonly base_dir
else
    readonly base_dir="$1"
fi

# Source the LuaRocks paths
eval "$(luarocks --local path)"

readonly exit_ok=0
readonly exit_software=2

##
# Use the `make` target of Luarocks to bundle the modules.
#
function create_bundle {
    cd "$base_dir" || exit
    luarocks --local make
}

create_bundle || exit "$exit_software"

exit "$exit_ok"