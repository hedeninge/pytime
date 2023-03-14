#!/usr/bin/env bash

execute() {
  load_config
  export_config
  exec "${PYTHEETOR}" "${CONFILE}" "$@"
}

load_config() {
  CONFILE="${BASH_SOURCE[0]%.sh}.conf"
  #  echo "Load CONFILE: ${CONFILE}"
  # shellcheck disable=SC1090
  . "${CONFILE}" && return 0
  echo "${BASH_SOURCE[0]}; Failed to load lib: ${CONFILE}"
  exit 1
}

export_config() {
  declare -a lines
  while IFS= read -r line; do
    lines+=("$line")
  done <"${CONFILE}"

  for line in "${lines[@]}"; do
    # skip comments
    [[ "$line" =~ ^#.*$ ]] && continue
    # skip empty lines
    [[ -z "$line" ]] && continue
    # skip lines that don't have an "="
    [[ "$line" =~ ^[^=]*$ ]] && continue
    IFS='=' read -r key rest <<<"$line"
    # skip if no key.
    if [[ -z "$key" ]]; then
      echo "BAD line: $line"
      continue
    fi
    #    echo " ------ key: $key"
    # shellcheck disable=SC2163
    export "$key"
  done
}

#_execute() {
#  #  CONFILE=$1
#  CUP_NAME=$1
#  load_lib
#  defunc "$@"
#  #  load_config "$@"
#  echo "CUP_NAME: ${CUP_NAME}"
#  #  echo "CUPXECUTOR: ${CUPXECUTOR}"
#  #  if [[ -f "${CUPXECUTOR}" ]]; then
#  #    echo "CUP_EXE exists: ${CUPXECUTOR}"
#  #  else
#  #    echo "CUP_EXE does not exist: ${CUPXECUTOR}"
#  #  fi
#  #  #  #  debug 'post load_lib'
#  #  #  #  debug "PYTIME_PROJECT_DIR: $PYTIME_PROJECT_DIR"
#  #  #  activenvate
#  #  #  run_pythee "$@"
#}

#_load_lib() {
#  #  echo "Load lib: BASH_SOURCE: ${BASH_SOURCE[0]}"
#  #  echo "Load lib: arg 0: $0"
#
#  REAL_SOURCE="${BASH_SOURCE[0]}"
#  if [[ -L "${REAL_SOURCE}" ]]; then
#    echo "Load lib: ${REAL_SOURCE} is a symlink"
#    REAL_SOURCE="$(readlink "${REAL_SOURCE}")"
#    echo "Load lib: REAL_SOURCE: ${REAL_SOURCE}"
#  fi
#
#  lib="$(realpath "$(dirname "${REAL_SOURCE}")/../components/pytime.lib.sh")"
#  # shellcheck disable=SC1090
#  . "$lib" && return 0
#  echo "Failed to load lib: $lib"
#  exit 1
#}

#_load_config() {
#  CONFILE=$1
#  echo "Load CONFILE: ${CONFILE}"
#  # shellcheck disable=SC1090
#  . "${CONFILE}" && return 0
#  echo "Failed to load lib: ${CONFILE}"
#  exit 1
#}

execute "$@"
