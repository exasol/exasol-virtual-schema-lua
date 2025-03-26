#!/bin/bash

# This script installs Luarocks on a machine that works with `apt` (Debian / Ubuntu).

set -euo pipefail

readonly exit_ok=0
readonly exit_software=2
readonly exit_usage=64

# Function to display help
display_help() {
  echo "Usage: $0 --lua-version=<version> [--path]" >&2
  echo "       $0 --help | -h" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  --lua-version=<v>   Specify the Lua version to install (mandatory)." >&2
  echo "  --path              Output the Luarocks path after execution." >&2
  echo "  --help | -h         Display this help message and exit." >&2
  echo "" >&2
  exit "$exit_usage"
}

lua_version=""
should_output_path=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --lua-version=*)
      lua_version="${arg#*=}"
      ;;
    --path)
      should_output_path=true
      ;;
    --help|-h)
      display_help
      ;;
    *)
      echo "Unknown option: '$arg'." >&2
      display_help
      ;;
  esac
done

if [[ -z "$lua_version" ]]; then
  echo "Please provide the Lua version with --lua-version=<version>" >&2
fi

# Luarocks constants
readonly luarocks_config_dir="$HOME/.luarocks"
readonly luarocks_command="luarocks --lua-version=${lua_version} --local"

# Function to install Lua and basic dependencies
install_dependencies() {
  sudo apt-get install -y "lua${lua_version}" "liblua${lua_version}-dev" luarocks
  luarocks --version
}

# Function to configure Luarocks
configure_luarocks() {
  mkdir -p "$luarocks_config_dir"
  echo "lua_version = \"${lua_version}\"" > "$luarocks_config_dir/config-${lua_version}.lua"
  echo "return \"${lua_version}\"" > "$luarocks_config_dir/default-lua-version.lua"
}

# Function to set up Luarocks paths and install dependencies
setup_luarocks() {
  $luarocks_command install --only-deps ./*.rockspec
}

output_paths() {
  # Output Luarocks path if --path is provided
  if $should_output_path; then
    $luarocks_command path
  fi
}

# Main Script Execution
install_dependencies && \
configure_luarocks && \
setup_luarocks && \
output_paths || \
exit "$exit_software"

exit "$exit_ok"