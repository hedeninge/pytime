#!/usr/bin/env bash

PYTIME_PROJECT_DIR="$(realpath "$(dirname "$0")"/..)"
PYTIME_ACTIVATE="${PYTIME_PROJECT_DIR}/venv/bin/activate"
PYTIME_PYTHEE="${PYTIME_PROJECT_DIR}/py/the_pythee.py"
PYTIME_SERVICE_DIR="${PYTIME_PROJECT_DIR}/systemd"
PYTIME_LOGS_DIR="${PYTIME_PROJECT_DIR}/logs"
PYTIME_LOG_FILE="${PYTIME_LOGS_DIR}/pytheetor.log"
PYTIME_BOOT_FILE='/tmp/pytime.boot'
#PYTIME_SERVICE="${PYTIME_PROJECT_DIR}/systemd/${PYTIME_SERVICE_NAME}"
PYTIME_SERVICE_NAME='pytime.service'
PYTIME_TIMER_NAME='pytime.timer'

#SYSTEM_CTL="sudo $(which systemctl) "
SYSTEM_CTL="$(which systemctl) --user "

activenvate() {
  #  defunc
  # shellcheck disable=SC1090
  . "$PYTIME_ACTIVATE" || fail "Failed to activate venv"
  PYTIME_PYTHON=$(which python3) || fail "Failed to find python"
  #  debug "PYTIME_PYTHON: ${PYTIME_PYTHON}"
}

other_run() {
  defunc "$@"
}

run_pythee() {
  defunc
  "${PYTIME_PYTHON}" "$PYTIME_PYTHEE" 'test' "$@"
}

systemd_install() {
  defunc
  systemd_install_unit "${PYTIME_SERVICE_NAME}"
  systemd_install_unit "${PYTIME_TIMER_NAME}"
  ${SYSTEM_CTL} daemon-reload
}

systemd_uninstall() {
  defunc
  systemd_uninstall_unit "${PYTIME_SERVICE_NAME}"
  systemd_uninstall_unit "${PYTIME_TIMER_NAME}"
  ${SYSTEM_CTL} daemon-reload
}

systemd_install_unit() {
  defunc
  local name file
  name="$1"
  debug "name: ${name}"
  file="${PYTIME_SERVICE_DIR}/${name}"
  debug "file: ${file}"
  if systemd_exists_unit "${name}"; then
    systemd_uninstall_unit "${name}"
  fi
  ${SYSTEM_CTL} link "${file}"
  if [[ "${name}" == *'.timer' ]]; then
    ${SYSTEM_CTL} enable "${name}"
  fi

  #  ${SYSTEM_CTL} --no-pager cat "${name}"
  txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"
  line1="$(echo "$txt" | head -n 1)"
  debug "${line1}"
}

systemd_uninstall_unit() {
  defunc
  local name
  name="$1"
  if systemd_exists_unit "${name}"; then
    ${SYSTEM_CTL} stop "${name}"
    if [[ "${name}" == *'.timer' ]]; then
      ${SYSTEM_CTL} clean --what=state "${name}"
    fi
    ${SYSTEM_CTL} disable "${name}"
  else
    echo "No unit file for: ${name}"
  fi
}

systemd_unit_file() {
  local name
  name="$1"
  local path
  if txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"; then
    #    echo "txt: $txt"
    line1="$(echo "$txt" | head -n 1)"
    path="${line1:2}"
    echo "$path"
  else
    echo "Failed to get unit file for: $name"
    return 1
  fi
}

systemd_exists_unit() {
  local name path
  name="$1"
  if path="$(systemd_unit_file "${name}")"; then
    if [ -f "$path" ]; then
      echo "${path} exists"
      return 0
    fi
  fi
  return 1
}

systemd_service_testrun() {
  defunc
  if ! systemd_exists_unit "${PYTIME_SERVICE_NAME}"; then
    echo "unit does not exist"
    exit 1
  else
    ${SYSTEM_CTL} start "${PYTIME_SERVICE_NAME}"
  fi
}

fail() {
  debug "FAIL: $*"
  exit 1
}

# shellcheck disable=SC2120
defunc() {
  debug "FUNC '${FUNCNAME[1]}' $*"
}

debug() {
  echo "$*"
  log "$*"
}

log() {
  #  mkdir -p "$PYTIME_LOGS_DIR"
  echo "$*" >>"$PYTIME_LOG_FILE"
}

reset_logs() {
  mkdir -p "$PYTIME_LOGS_DIR"
  for f in "$PYTIME_LOGS_DIR"/*.log; do
    #    echo -n >"$f"
    echo 'CLEANSED' >"$f"
  done
  debug "reset_logs"
}

boot_check() {
  if ! exists_boot_file; then
    debug "boot reset"
    touch "$PYTIME_BOOT_FILE"
    reset_logs
    debug "boot checked"
  fi
}

exists_boot_file() {
  [[ -f "$PYTIME_BOOT_FILE" ]]
}

boot_check

#### fluff ####

#  echo "EXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*"
# in blue text:
#  echo -e "\e[34mEXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*\e[0m"
