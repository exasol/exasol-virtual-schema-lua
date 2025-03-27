#!/bin/bash

# This script uses `apt-get` to install Luarocks.

set -euo pipefail

readonly lua_version="5.4"

sudo apt-get install lua${lua_version} liblua${lua_version}-dev luarocks
mkdir -p "$HOME"/.luarocks
echo "lua_version = \"$lua_version\"" > "$HOME"/.luarocks/config-${lua_version}.lua
echo "return \"$lua_version\"" > "$HOME"/.luarocks/default-lua-version.lua