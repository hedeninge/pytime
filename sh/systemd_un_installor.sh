#!/usr/bin/env bash

execute() {
  load_lib
  systemd_uninstall
}

load_lib() {
  lib="$(dirname "${BASH_SOURCE[0]}")/pytime.lib.sh"
  # shellcheck disable=SC1090
  . "$lib" && return 0
  echo "Failed to load lib: $lib"
  exit 1
}

execute "$@"
