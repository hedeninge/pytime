#!/usr/bin/env bash

execute() {
  print_new_global_vars
#  show_unit_names
}

show_unit_names() {
  load_lib
  service_template_name
  service_instance_name
  timer_template_name
  timer_instance_name
}

print_new_global_vars() {
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

  declare -a diff_keys
  for key in "${new_keys[@]}"; do
    if [[ ! " ${origin_keys[*]} " == *"$key"* ]]; then
      diff_keys+=("$key")
      printf "%36s = %s\n" "$key" "${!key}"
    fi
  done

  echo "diff_keys: ${diff_keys[*]}"
}

load_lib() {
  lib="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../components/pytime.lib.sh")"
  # shellcheck disable=SC1090
  . "$lib" && return 0
  echo "Failed to load lib: $lib"
  exit 1
}

execute "$@"
