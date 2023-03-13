#!/usr/bin/env bash

execute() {
  exe="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../components/pytheetor")"
  "$exe" "$@"
}

execute "$@"
