#!/usr/bin/env bash
TEST_REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_repo_path() { printf '%s/%s\n' "$TEST_REPO_ROOT" "${1:-}"; }
test_path() { ruby "$TEST_REPO_ROOT/tools/test_paths.rb" path "$1"; }
test_setting() { ruby "$TEST_REPO_ROOT/tools/test_paths.rb" setting "$1"; }
