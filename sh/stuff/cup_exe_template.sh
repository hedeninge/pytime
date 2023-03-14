#!/usr/bin/env bash

execute() {
  #  echo "EXE ${BASH_SOURCE[0]} $*"
  load_config
  #  echo "CUPXECUTOR: ${CUPXECUTOR}"
  exec "${CUPXECUTOR}" "${CONFILE}" "$@"
}

load_config() {
  CONFILE="${BASH_SOURCE[0]%.sh}.conf"
  #  echo "Load CONFILE: ${CONFILE}"
  # shellcheck disable=SC1090
  . "${CONFILE}" && return 0
  echo "${BASH_SOURCE[0]}; Failed to load lib: ${CONFILE}"
  exit 1
}

execute "$@"
