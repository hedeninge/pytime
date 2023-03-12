#!/usr/bin/env bash

execute() {
  echo -e "\e[34mEXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*\e[0m"
  load_lib
  systemd_service_testrun
#  systemd_install
}

load_lib() {
  lib="$(dirname "${BASH_SOURCE[0]}")/pytime.lib.sh"
  # shellcheck disable=SC1090
  . "$lib" && return 0
  echo "Failed to load lib: $lib"
  exit 1
}

execute "$@"
