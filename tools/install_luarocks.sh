#!/bin/bash

set -euo pipefail

readonly exit_usage=64
readonly exit_ok=0


if ! parsed_options=$(getopt --options "" --longoptions "lua-version:" --name "$0" -- "$@"); then
  echo "Allowed options are: --lua-version=<version>"
  exit "$exit_usage"
fi
eval set -- "$parsed_options"

lua_version=""
while true; do
  case "$1" in
    --lua-version)
      lua_version="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1"
      echo "Allowed options are: --lua-version=<version>"
      exit "$exit_usage"
      ;;
  esac
done

if [[ -z "${lua_version:-}" ]]; then
  echo "Please provide the Lua version with --lua-version=<version>"
  exit "$exit_usage"
fi

sudo apt-get install "lua${lua_version}" "liblua${lua_version}-dev" luarocks
luarocks --version
mkdir -p "$HOME"/.luarocks
echo "lua_version = \"$lua_version\"" > "$HOME/.luarocks/config-${lua_version}.lua"
echo "return \"$lua_version\"" > "$HOME/.luarocks/default-lua-version.lua"

exit "$exit_ok"