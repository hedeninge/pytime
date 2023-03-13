#!/usr/bin/env bash

execute() {
#  env
  load_lib
  test_basic
}

load_lib() {
  lib="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../components/pytime.lib.sh")"
  # shellcheck disable=SC1090
  . "$lib" && return 0
  echo "Failed to load lib: $lib"
  exit 1
}

execute "$@"
