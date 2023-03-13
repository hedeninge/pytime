#!/usr/bin/env bash

initialize() {
  init_vars
  boot_check
  env_ize
  systemd_templatize
}

init_vars() {
  PYTIME_NAME='pytime'
  PYTIME_DEFAULT_PYTHEE='py/the_pythee.py'
  PYTIME_DEFAULT_VENV='venv'
  PYTIME_PROJECT_DIR="$(realpath "$(dirname "$0")"/../..)"
  #  PYTIME_ACTIVATE="${PYTIME_PROJECT_DIR}/venv/bin/activate"
  PYTIME_ACTIVATE="${PYTIME_PROJECT_DIR}/${PYTIME_DEFAULT_VENV}/bin/activate"
  PYTIME_PYTHEE="${PYTIME_PROJECT_DIR}/${PYTIME_DEFAULT_PYTHEE}"
  PYTIME_SERVICE_DIR="${PYTIME_PROJECT_DIR}/systemd"
  PYTIME_LOGS_DIR="${PYTIME_PROJECT_DIR}/logs"
  PYTIME_LOG_FILE="${PYTIME_LOGS_DIR}/pytheetor.log"
  PYTIME_BOOT_FILE="/tmp/${PYTIME_NAME}.boot"

  # Switch between system and user mode:
  #SYSTEM_CTL="sudo $(which systemctl) "
  SYSTEM_CTL="$(which systemctl) --user "
  #Also for journalctl:
  #JOURNAL_CTL="sudo $(which journalctl) "
  JOURNAL_CTL="$(which journalctl) --user "
}

systemd_templatize() {
  local esc_path
  esc_path=$(systemd-escape --path "$PYTIME_PROJECT_DIR"/sh/components/pytheetor)
  #  debug "esc_path: ${esc_path}"
  PYTIME_INSTANCE_NAME="${esc_path}"
}

env_ize() {
  #  defunc
  local env_file
  env_file="${PYTIME_PROJECT_DIR}/.env.${PYTIME_NAME}"
  if [[ ! -f "${env_file}" ]]; then
    # Write env file with heredoc:
    cat <<-EOF >"${env_file}"
## A path to the python being launched.
## The path can be relative to the project dir or absolute.
## An absolute starts with a '/'.
## A relative path should just start with name of its path from the project dir - no leading '.' or stuff.
## This is the default by relative path, which will be used if ENV_PYTIME_PYTHEE is not set here (or fails):
ENV_PYTIME_PYTHEE='${PYTIME_DEFAULT_PYTHEE}'
## An example of an alternate file as a relative path:
# ENV_PYTIME_PYTHEE='py/alternative_pythee.py'
##And an example of the default file as an absolute path:
# ENV_PYTIME_PYTHEE='${PYTIME_PYTHEE}'
##
## Almost the same goes for venv:
ENV_PYTIME_VENV='${PYTIME_DEFAULT_VENV}'
ENV_PYTIME_MISSING_VENV_ACTION='create' # 'create' or 'fail'
EOF
  fi
  # shellcheck disable=SC1090
  . "${env_file}" || fail "Failed to load env file: ${env_file}"
  # if ENV_PYTIME_PYTHEE is set, use it:
  if [[ -n "${ENV_PYTIME_PYTHEE}" ]]; then
    local abs_pythee
    # if ENV_PYTIME_PYTHEE is not an absolute path, make it one:
    if [[ "${ENV_PYTIME_PYTHEE:0:1}" != '/' ]]; then
      abs_pythee="${PYTIME_PROJECT_DIR}/${ENV_PYTIME_PYTHEE}"
    else
      abs_pythee="${ENV_PYTIME_PYTHEE}"
    fi
    if [[ -f "${abs_pythee}" ]]; then
      PYTIME_PYTHEE="${abs_pythee}"
    fi
  fi

  if [[ -n "${ENV_PYTIME_VENV}" ]]; then
    local abs_venv
    # if ENV_PYTIME_VENV is not an absolute path, make it one:
    if [[ "${ENV_PYTIME_VENV:0:1}" != '/' ]]; then
      abs_venv="${PYTIME_PROJECT_DIR}/${ENV_PYTIME_VENV}"
    else
      abs_venv="${ENV_PYTIME_VENV}"
    fi
    #    #    if [[ -d "${abs_venv}" ]]; then
    PYTIME_ACTIVATE="${abs_venv}/bin/activate"
    #    #    fi
  fi

  if [[ ! -f "${PYTIME_ACTIVATE}" ]]; then
    #    debug "ENV_PYTIME_MISSING_VENV_ACTION: ${ENV_PYTIME_MISSING_VENV_ACTION}"
    if [[ "${ENV_PYTIME_MISSING_VENV_ACTION}" == 'create' ]]; then
      create_venv
    else
      fail "Failed to find venv: ${PYTIME_ACTIVATE}"
    fi
  fi

  if [[ ! -f "${PYTIME_ACTIVATE}" ]]; then
    fail "Really failed to create or find venv: ${PYTIME_ACTIVATE}"
  fi

}

create_venv() {
  defunc
  local venv_dir
  venv_dir=$(dirname "$(dirname "${PYTIME_ACTIVATE}")")
  debug "venv_dir: ${venv_dir}"
  mkdir -p "${venv_dir}" || fail "Failed to create venv dir: ${venv_dir}"
  debug "Creating venv ... : ${venv_dir}"
  python3 -m venv "${venv_dir}" || fail "Failed to create venv: ${venv_dir}"
  #  --prompt PROMPT       Provides an alternative prompt prefix for this environment.
  activenvate
  python3 -m pip install --upgrade pip
  debug "VIRTUAL_ENV: ${VIRTUAL_ENV}"
  req_file="${PYTIME_PROJECT_DIR}/packages.req.txt"
  if [[ -f "${req_file}" ]]; then
    # shellcheck disable=SC1090
    #    . "${PYTIME_ACTIVATE}" || fail "Failed to activate venv"
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      debug "Installing requirements: ${req_file}"
      pip install --progress-bar=on --upgrade -r "${req_file}" || fail "Failed to install requirements: ${req_file}"
    else
      fail "Apparently failed to activate venv: ${PYTIME_ACTIVATE}"
    fi
  fi
  deactivate
}

activenvate() {
  defunc
  if [[ $(type -t deactivate) == 'function' ]]; then
    deactivate
  fi
  # shellcheck disable=SC1090
  . "$PYTIME_ACTIVATE" || fail "Failed to activate venv"
  debug "VIRTUAL_ENV: ${VIRTUAL_ENV}"
  PYTIME_PYTHON=$(which python3) || fail "Failed to find python"
  #  debug "PYTIME_PYTHON: ${PYTIME_PYTHON}"
}

other_run() {
  defunc "$@"
}

run_pythee() {
  defunc "${PYTIME_PYTHON}" "$PYTIME_PYTHEE" 'test' "$@"
  "${PYTIME_PYTHON}" "$PYTIME_PYTHEE" 'test' "$@"
}

journalctl_follow_service() {
  local name
  name="$(service_instance_name)"
  defunc "${name}"
  ${JOURNAL_CTL} -fu "${name}"
}

journalctl_follow_timer() {
  local name
  name="$(timer_instance_name)"
  defunc "${name}"
  ${JOURNAL_CTL} -fu "${name}"
}

systemd_start_timer() {
  local name
  name="$(timer_instance_name)"
  defunc "${name}"
  ${SYSTEM_CTL} start "${name}"
}

systemd_stop_timer() {
  local name
  name="$(timer_instance_name)"
  defunc "${name}"
  ${SYSTEM_CTL} stop "${name}"
}

unit_name() {
  local unit_type name
  unit_type="$1"
  name="${PYTIME_NAME}@"
  if [[ $2 != 'template' ]]; then
    name="${name}${PYTIME_INSTANCE_NAME}"
  fi
  name="${name}.${unit_type}"
  echo "${name}"
}

service_template_name() {
  unit_name 'service' 'template'
}

service_instance_name() {
  unit_name 'service'
}

timer_template_name() {
  unit_name 'timer' 'template'
}

timer_instance_name() {
  unit_name 'timer'
}

systemd_origin_file() {
  local name file
  name="$1"
  file="${PYTIME_SERVICE_DIR}/${name}"
  echo "${file}"
}

systemd_install() {
  defunc
  systemd_install_unit "$(service_template_name)"
  #  systemd_install_unit "${PYTIME_NAME}" 'service' #'template'
  systemd_enable_instance_unit "$(service_instance_name)"
  #  systemd_enable_instance_unit "${PYTIME_NAME}" 'service' "${PYTIME_INSTANCE_NAME}"

  systemd_install_unit "$(timer_template_name)"
  #  systemd_install_unit "${PYTIME_NAME}" 'timer' #'template'
  systemd_enable_instance_unit "$(timer_instance_name)"
  #  systemd_enable_instance_unit "${PYTIME_NAME}" 'timer' "${PYTIME_INSTANCE_NAME}"

  ${SYSTEM_CTL} daemon-reload
}

systemd_uninstall() {
  defunc

  systemd_disable_instance_unit "$(service_instance_name)"
  #  systemd_disable_instance_unit "${PYTIME_NAME}" 'service' "${PYTIME_INSTANCE_NAME}"

  systemd_uninstall_unit "$(service_template_name)"
  #  systemd_uninstall_unit "${PYTIME_NAME}" 'service' #'template'

  systemd_disable_instance_unit "$(timer_instance_name)"
  #  systemd_disable_instance_unit "${PYTIME_NAME}" 'timer' "${PYTIME_INSTANCE_NAME}"
  systemd_uninstall_unit "$(timer_template_name)"
  #  systemd_uninstall_unit "${PYTIME_NAME}" 'timer' #'template'

  ${SYSTEM_CTL} daemon-reload
}

systemd_install_unit() {
  defunc
  local name file
  name="$1"
  file="$(systemd_origin_file "${name}")"
  if systemd_exists_unit "${name}"; then
    systemd_uninstall_unit "${name}"
  fi
  ${SYSTEM_CTL} link "${file}"
  txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"
  line1="$(echo "$txt" | head -n 1)"
  debug "${line1}"
}

#_systemd_install_unit() {
#  defunc
#  local base_name name file txt line1
#  base_name="$1"
#  unit_type="$2"
#  name="${base_name}@.${unit_type}"
#  #  debug "base_name: ${base_name}"
#  #  debug "unit_type: ${unit_type}"
#  #  debug "name: ${name}"
#  file="${PYTIME_SERVICE_DIR}/${name}"
#  #  debug "file: ${file}"
#  if systemd_exists_unit "${name}"; then
#    systemd_uninstall_unit "${name}"
#  fi
#  ${SYSTEM_CTL} link "${file}"
#  #  if [[ "${name}" == *'.timer' ]]; then
#  #    ${SYSTEM_CTL} enable "${name}"
#  #  fi
#
#  #  ${SYSTEM_CTL} --no-pager cat "${name}"
#  txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"
#  line1="$(echo "$txt" | head -n 1)"
#  debug "${line1}"
#}

systemd_uninstall_unit() {
  defunc
  local name
  name="$1"
  if systemd_exists_unit "${name}"; then
    ${SYSTEM_CTL} disable "${name}"
  else
    echo "No unit file for: ${name}"
  fi
}

#_systemd_uninstall_unit() {
#  defunc
#  local base_name name file
#  base_name="$1"
#  unit_type="$2"
#  name="${base_name}@.${unit_type}"
#  #  debug "base_name: ${base_name}"
#  #  debug "unit_type: ${unit_type}"
#  #  debug "name: ${name}"
#  if systemd_exists_unit "${name}"; then
#    #    ${SYSTEM_CTL} stop "${name}"
#    #    if [[ "${unit_type}" == 'timer' ]]; then
#    #      ${SYSTEM_CTL} clean --what=state "${name}"
#    #    fi
#    ${SYSTEM_CTL} disable "${name}"
#  else
#    echo "No unit file for: ${name}"
#  fi
#}

systemd_enable_instance_unit() {
  defunc
  local name
  name="$1"
  ${SYSTEM_CTL} enable "${name}"
  if [[ "${name}" == *'.timer' ]]; then
    ${SYSTEM_CTL} start "${name}"
  fi
}

#_systemd_enable_instance_unit() {
#  defunc
#  local base_name name
#  base_name="$1"
#  unit_type="$2"
#  instance_name="$3"
#  name="${base_name}@${instance_name}.${unit_type}"
#  #  debug "base_name: ${base_name}"
#  #  debug "unit_type: ${unit_type}"
#  #  debug "instance_name: ${instance_name}"
#  #  debug "name: ${name}"
#  ${SYSTEM_CTL} enable "${name}"
#  if [[ "${unit_type}" == 'timer' ]]; then
#    ${SYSTEM_CTL} start "${name}"
#  fi
#}

systemd_disable_instance_unit() {
  defunc
  local name
  name="$1"
  if [[ "${unit_type}" == 'timer' ]]; then
    ${SYSTEM_CTL} stop "${name}"
    ${SYSTEM_CTL} clean --what=state "${name}"
  fi
  ${SYSTEM_CTL} disable "${name}"
}

#_systemd_disable_instance_unit() {
#  defunc
#  local base_name name
#  base_name="$1"
#  unit_type="$2"
#  instance_name="$3"
#  name="${base_name}@${instance_name}.${unit_type}"
#  #  debug "base_name: ${base_name}"
#  #  debug "unit_type: ${unit_type}"
#  #  debug "instance_name: ${instance_name}"
#  #  debug "name: ${name}"
#  if [[ "${unit_type}" == 'timer' ]]; then
#    ${SYSTEM_CTL} stop "${name}"
#    ${SYSTEM_CTL} clean --what=state "${name}"
#  fi
#  ${SYSTEM_CTL} disable "${name}"
#}

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
  if ! systemd_exists_unit "$(service_instance_name)"; then
    echo "unit does not exist"
    exit 1
  else
    ${SYSTEM_CTL} start "$(service_instance_name)"
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

log_follow() {
  tail -F "$PYTIME_LOG_FILE"
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
  mkdir -p "$PYTIME_LOGS_DIR"
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

exists_logs_dir() {
  [[ -d "$PYTIME_LOGS_DIR" ]]
}

develop_pytime() {
  defunc
  show_vars
}

test_basic() {
  defunc
  show_vars
}

show_vars() {
  defunc
  keys=(PYTIME_PYTHON ENV_PYTIME_MISSING_VENV_ACTION ENV_PYTIME_PYTHEE ENV_PYTIME_VENV JOURNAL_CTL PYTIME_ACTIVATE PYTIME_BOOT_FILE PYTIME_DEFAULT_PYTHEE PYTIME_DEFAULT_VENV PYTIME_INSTANCE_NAME PYTIME_LOGS_DIR PYTIME_LOG_FILE PYTIME_NAME PYTIME_PROJECT_DIR PYTIME_PYTHEE PYTIME_SERVICE_DIR SYSTEM_CTL)
  echo
  for key in "${keys[@]}"; do
    echo "$key=${!key}"
  done
  echo
  # echo all global variables:
  ##   shellcheck disable=SC2154
  #  for var in "${!PYTIME_@}"; do
  #    echo "$var=${!var}"
  #  done
  #  echo
  #  env
}

initialize

#### fluff ####

#  echo "EXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*"
# in blue text:
#  echo -e "\e[34mEXEFUNC '$(basename "$0")'  '${FUNCNAME[0]}' $*\e[0m"
