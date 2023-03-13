#!/usr/bin/env bash

execute() {
  locals_str='lib key dxp line kryt origin_s COLUMNS LINES'
  declare -a avoids

  # shellcheck disable=SC2206
  avoids=($locals_str)
  # make array from space delimited  string:

  local key dxp line kryt
  dxp=$(declare -p)
  declare -a origin_keys
  while read -r line; do
    # extract the key before the "="
    key=$(echo "$line" | grep -oP '.*\K(?<=\s)(\w+)(?==)')
    #    echo "key: $key"
    origin_keys+=("$key")
  done <<<"$dxp"
#  echo "origin_keys: ${origin_keys[*]}"
#  kryt="kryten"

  load_lib

  declare -a new_keys
  dxp=$(declare -p)
  while read -r line; do
    # extract the key before the "="
    key=$(echo "$line" | grep -oP '.*\K(?<=\s)(\w+)(?==)')
    #    echo "key: $key"
    new_keys+=("$key")
  done <<<"$dxp"

  for key in "${avoids[@]}"; do
    new_keys=("${new_keys[@]/$key/}")
  done

  #  echo "new_keys: ${new_keys[*]}"

  for key in "${new_keys[@]}"; do
    if [[ ! " ${origin_keys[*]} " == *"$key"* ]]; then
      printf "%36s = %s\n" "$key" "${!key}"
    fi
  done
}

load_lib() {
  lib="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../components/pytime.lib.sh")"
  # shellcheck disable=SC1090
  . "$lib" && return 0
  echo "Failed to load lib: $lib"
  exit 1
}

execute "$@"
