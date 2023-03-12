#!/usr/bin/env bash

initialize() {
  init_vars
  systemd_templatize
  boot_check
}

init_vars() {
  PYTIME_NAME='pytime'
  PYTIME_PROJECT_DIR="$(realpath "$(dirname "$0")"/..)"
  PYTIME_ACTIVATE="${PYTIME_PROJECT_DIR}/venv/bin/activate"
  PYTIME_PYTHEE="${PYTIME_PROJECT_DIR}/py/the_pythee.py"
  PYTIME_SERVICE_DIR="${PYTIME_PROJECT_DIR}/systemd"
  PYTIME_LOGS_DIR="${PYTIME_PROJECT_DIR}/logs"
  PYTIME_LOG_FILE="${PYTIME_LOGS_DIR}/pytheetor.log"
  PYTIME_BOOT_FILE="/tmp/${PYTIME_NAME}.boot"

  # Switch between system and user mode:
  #SYSTEM_CTL="sudo $(which systemctl) "
  SYSTEM_CTL="$(which systemctl) --user "
}

systemd_templatize() {
  esc_path=$(systemd-escape --path "$PYTIME_PROJECT_DIR")
  #  debug "esc_path: ${esc_path}"
  pytheetor_esc_path="${esc_path}-sh-pytheetor"
  #  debug "pytheetor_esc_path: ${pytheetor_esc_path}"
  PYTIME_INSTANCE_NAME="${pytheetor_esc_path}"
  PYTIME_SERVICE_NAME="${PYTIME_NAME}@.${PYTIME_INSTANCE_NAME}.service"
}

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
  systemd_install_unit "${PYTIME_NAME}" 'service' #'template'
  systemd_enable_instance_unit "${PYTIME_NAME}" 'service' "${PYTIME_INSTANCE_NAME}"

  systemd_install_unit "${PYTIME_NAME}" 'timer' #'template'
  systemd_enable_instance_unit "${PYTIME_NAME}" 'timer' "${PYTIME_INSTANCE_NAME}"

  ${SYSTEM_CTL} daemon-reload
}

systemd_uninstall() {
  defunc
  systemd_disable_instance_unit "${PYTIME_NAME}" 'service' "${PYTIME_INSTANCE_NAME}"
  systemd_uninstall_unit "${PYTIME_NAME}" 'service' #'template'

  systemd_disable_instance_unit "${PYTIME_NAME}" 'timer' "${PYTIME_INSTANCE_NAME}"
  systemd_uninstall_unit "${PYTIME_NAME}" 'timer' #'template'

  ${SYSTEM_CTL} daemon-reload
}

systemd_install_unit() {
  defunc
  local base_name name file
  base_name="$1"
  unit_type="$2"
  name="${base_name}@.${unit_type}"
  #  debug "base_name: ${base_name}"
  #  debug "unit_type: ${unit_type}"
  #  debug "name: ${name}"
  file="${PYTIME_SERVICE_DIR}/${name}"
  #  debug "file: ${file}"
  if systemd_exists_unit "${name}"; then
    systemd_uninstall_unit "${name}"
  fi
  ${SYSTEM_CTL} link "${file}"
  #  if [[ "${name}" == *'.timer' ]]; then
  #    ${SYSTEM_CTL} enable "${name}"
  #  fi

  #  ${SYSTEM_CTL} --no-pager cat "${name}"
  txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"
  line1="$(echo "$txt" | head -n 1)"
  debug "${line1}"
}

systemd_uninstall_unit() {
  defunc
  local base_name name file
  base_name="$1"
  unit_type="$2"
  name="${base_name}@.${unit_type}"
  #  debug "base_name: ${base_name}"
  #  debug "unit_type: ${unit_type}"
  #  debug "name: ${name}"
  if systemd_exists_unit "${name}"; then
    #    ${SYSTEM_CTL} stop "${name}"
    #    if [[ "${unit_type}" == 'timer' ]]; then
    #      ${SYSTEM_CTL} clean --what=state "${name}"
    #    fi
    ${SYSTEM_CTL} disable "${name}"
  else
    echo "No unit file for: ${name}"
  fi
}

systemd_enable_instance_unit() {
  defunc
  local base_name name
  base_name="$1"
  unit_type="$2"
  instance_name="$3"
  name="${base_name}@${instance_name}.${unit_type}"
  #  debug "base_name: ${base_name}"
  #  debug "unit_type: ${unit_type}"
  #  debug "instance_name: ${instance_name}"
  #  debug "name: ${name}"
  ${SYSTEM_CTL} enable "${name}"
}

systemd_disable_instance_unit() {
  defunc
  local base_name name
  base_name="$1"
  unit_type="$2"
  instance_name="$3"
  name="${base_name}@${instance_name}.${unit_type}"
  #  debug "base_name: ${base_name}"
  #  debug "unit_type: ${unit_type}"
  #  debug "instance_name: ${instance_name}"
  #  debug "name: ${name}"
  if [[ "${unit_type}" == 'timer' ]]; then
    ${SYSTEM_CTL} stop "${name}"
    ${SYSTEM_CTL} clean --what=state "${name}"
  fi
  ${SYSTEM_CTL} disable "${name}"
}

systemd_unit_file() {
  local name
  name="$1"
  local path
  if txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"; then
    #    echo "txt: $txt"
    line1="$(echo "$txt" | head -n 1)"
    path="${line1:2}"
    echo "$path" # YES ECHO HERE!
  else
    debug "Failed to get unit file for: $name"
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

develop_pytime() {
  defunc
  show_vars
}

show_vars() {
  defunc
  echo " - PYTIME_PROJECT_DIR: ${PYTIME_PROJECT_DIR}"
  echo " - PYTIME_ACTIVATE: ${PYTIME_ACTIVATE}"
  echo " - PYTIME_PYTHEE: ${PYTIME_PYTHEE}"
  echo " - PYTIME_SERVICE_DIR: ${PYTIME_SERVICE_DIR}"
  echo " - PYTIME_LOGS_DIR: ${PYTIME_LOGS_DIR}"
  echo " - PYTIME_LOG_FILE: ${PYTIME_LOG_FILE}"
  echo " - PYTIME_BOOT_FILE: ${PYTIME_BOOT_FILE}"
  echo " - PYTIME_SERVICE_NAME: ${PYTIME_SERVICE_NAME}"
  echo " - SYSTEM_CTL: ${SYSTEM_CTL}"
  echo
}

initialize

#### fluff ####

#  echo "EXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*"
# in blue text:
#  echo -e "\e[34mEXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*\e[0m"
