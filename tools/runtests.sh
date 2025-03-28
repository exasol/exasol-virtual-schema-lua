#!/bin/bash

# This script runs Lua unit tests, collects coverage and runs static code analysis.

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
readonly src_module_path="$base_dir/src/main/lua"
readonly src_exasol_evsl_path="$src_module_path/exasol/evsl"
readonly test_module_path="$base_dir/spec"
readonly target_dir="$base_dir/target"
readonly reports_dir="$target_dir/luaunit-reports"
readonly luacov_dir="$target_dir/luacov-reports"

function create_target_directories {
    mkdir -p "$reports_dir"
    mkdir -p "$luacov_dir"
}

##
# Run the unit tests and collect code coverage.
#
# Return error status in case there were failures.
#
function run_tests {
    cd "$base_dir" || exit
    luarocks --local test
}

##
# Collect the coverage results into a single file.
#
# Return exit status of coverage collector.
#
function collect_coverage_results {
    echo
    echo "Collecting code coverage results"
    luacov --config "$base_dir/.coverage_config.lua"
    return "$?"
}

##
# Move the coverage results into the target directory.
#
# Return exit status of `mv` command.
#
function move_coverage_results {
    echo "Moving coverage results to $luacov_dir"
    mv "$base_dir"/luacov.*.out "$luacov_dir"
    return "$?"
}

##
# Print the summary section of the code coverage report to the console
#
function print_coverage_summary {
    echo
    grep --after 500 'File\s*Hits' "$luacov_dir/luacov.report.out"
}

##
# Analyze the Lua code with "luacheck".
#
# Return exit status of code coverage.
#
function run_static_code_analysis {
    echo
    echo "Running static code analysis"
    echo
    luacheck "$src_exasol_evsl_path" "$test_module_path" --codes --ignore 111 --ignore 112 --ignore 212
    return "$?"
}

create_target_directories
run_tests \
  && collect_coverage_results \
  && move_coverage_results \
  && print_coverage_summary \
  && run_static_code_analysis \
  || exit "$exit_software"

exit "$exit_ok"