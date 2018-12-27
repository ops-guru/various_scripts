#!/usr/bin/env bash
# vim: ts=4 sw=4 et
#set -o xtrace
CONFIGS=(
    "${ARTIFACTORY_CONFIG:-"${PWD}/artifactory.config.sh"}"
)

function load_config() {
    local -a configs=("${@}")
    if [[ "${#configs[@]}" -eq 0 ]]; then
        configs+=("${CONFIGS[@]}")
    fi
    for config in "${configs[@]}"; do
        # only load existing files
        if [[ -r "${config}" ]]; then
            # shellcheck disable=SC1090
            source "${config}"
        else
            echo "WARN: config file ${config} is not readable."
        fi
    done
}

function mypushd() {
    command pushd "$@" > /dev/null || { echo "FATAL: failed to pushd ${*}"; exit 1; }
}

function mypopd() {
    command popd > /dev/null || { echo "FATAL: failed to popd"; exit 1; }
}

function backup_env() {
    local -a vars_to_backup=(
        "PATH"
        "http_proxy"
        "https_proxy"
        "no_proxy"
    )

    for var_name in "${vars_to_backup[@]}"; do
        var_value=$( eval echo "\$${var_name}" )
        if [[ -z "${var_value}" ]]; then
            continue
        fi
        backup_name="OLD_${var_name}"
        eval "export ${backup_name}=\"${var_value}\""
    done
}

function restore_env() {
    local -a vars_to_restore=(
        "PATH"
        "http_proxy"
        "https_proxy"
        "no_proxy"
    )
    for var_name in "${vars_to_restore[@]}"; do
        var_value=$( eval echo "\$OLD_${var_name}" )
        if [[ -z "${var_value}" ]]; then
            continue
        fi
        eval "export ${var_name}=\"${var_value}\""
    done
}

function lazy_setup_jfrog_cli() {
    local \
        jcli_url \
        jcli_path \
        path_arr \
        found
    jcli_url="${1?"cannot continue without jcli_url"}"
    jcli_path="${2:-"${JCLI_PATH}"}"
    found=0
    if type jfrog > /dev/null; then
        echo "JFrog CLI is already installed at $(type jfrog 2> /dev/null)"
        return 0
    fi
    IFS=':' read -ar path_arr <<< "${PATH}"
    for fpath in "${path_arr[@]}"; do
        if [[ "${jcli_path}" != "${fpath}" ]]; then
            continue
        fi
        found=1
    done
    mypushd "${PWD}"
    if [[ "${found}" -eq 0 ]]; then
        echo "-OLD PATH=$PATH"
        export PATH="${jcli_path}:${PATH}"
        echo "+NEW PATH=$PATH"
    fi
    mkdir -p "${jcli_path}"
    cd "${jcli_path}" || { echo "FATAL: failed to chdir to ${jcli_path}"; exit 1; }
    curl -fL "${jcli_url}" | sh
    chmod +x "jfrog"
    mypopd
}



function jfrog_cli_config() {
    local \
        id \
        url \
        user \
        apikey
    id="${1?"cannot continue without id"}"
    url="${2?"cannot continue without url"}"
    user="${3?"cannot continue without user"}"
    apikey="${4?"cannot continue without apikey"}"
    jfrog rt \
        config \
            --interactive=false \
            --url="${url}" \
            --user="${user}" \
            --apikey="${apikey}"
            "${id}"
    return $?
}

function lazy_config_jfrog_cli() {
    local \
        rt_id \
        url \
        user \
        apikey \
        rt_id_raw \
        rt_id_old \
        url_raw \
        url_old \
        user_raw \
        user_old
    rt_id="${1:-"${ARTIFACTORY_ID}"}"
    url="${2:-"${ARTIFACTORY_URL}"}"
    user="${3:-"${ARTIFACTORY_USER}"}"
    apikey="${4:-"${ARTIFACTORY_APIKEY}"}"

    if [[ "${JCLI_CONFIG_FORCE}" -ne 0 ]]; then
        echo "jcli configuration forced (JCLI_CONFIG_FORCE=${JCLI_CONFIG_FORCE})"
        jfrog_cli_config "${rt_id}" "${url}" "${user}" "${apikey}"
        return $?
    fi
    rt_id_raw="$( jfrog rt config show | grep -w "Server ID:" )"
    rt_id_old="${rt_id_raw//Server\ ID:\ /}"
    if ! [ "$rt_id_old" == "$rt_id" ]; then
        echo "Artifactory Server ID: ${rt_id} does not exist, configuring"
        jfrog_cli_config "${rt_id}" "${url}" "${user}" "${apikey}"
        return $?
    fi
    url_raw="$( jfrog rt config show | grep -w "Url:" )"
    url_old="${url_raw//Url:\ /}"
    if ! [ "$url_old" == "$url" ]; then
        echo "Artifactory Server ID: ${rt_id} differs in url, configuring"
        jfrog_cli_config "${rt_id}" "${url}" "${user}" "${apikey}"
        return $?
    fi
    user_raw="$( jfrog rt config show | grep -w "User:" )"
    user_old="${user_raw//User:\ /}"
    if ! [ "$user_old" == "$user" ]; then
        echo "Artifactory Server ID: ${rt_id} differs in user, configuring"
        jfrog_cli_config "${rt_id}" "${url}" "${user}" "${apikey}"
        return $?
    fi
    echo "Artifactory Server ID: ${rt_id} is alread configured"
}

function download_things() {
    local \
        data_dir
    data_dir="${1?cannot continue without data_dir}"
    mypushd "${PWD}"
    cd "${data_dir}" || { echo "FATAL: failed to chdir to ${data_dir}"; exit 1; }
    for rtfact in "${ARTIFACTS_ARR[@]}"; do
        jfrog rt dl "${rtfact}" .
    done
    mypopd
    return $?
}

function upload_things() {
    local \
        data_dir \
        target_repo
    data_dir="${1?cannot continue without data_dir}"
    target_repo="${2:-"${ARTIFACTORY_TARGET_REPO}"}"
    mypushd "${PWD}"
    cd "${data_dir}" || { echo "FATAL: cannot chdir to ${data_dir}"; exit 1; }
    jfrog rt upload '*.rpm' "${target_repo}/"
    mypopd
}

function gen_datadir() {
    local \
        prefix \
        suffix
    prefix="${1:-"${HOME}"}"
    suffix="${2:-"jfrog"}"
    mktemp -d -p "${prefix}" --suffix="${suffix}"
}

function cleanup() {
    local \
        data_dir \
    data_dir="${1?cannot continue without data_dir}"
    echo "cleaning up data_dir=${data_dir}"
    rm -fr "${data_dir}"
    # shellcheck disable=SC2154
    if [[ -n "${old_http_proxy}" ]]; then
        export http_proxy="${old_http_proxy}"
    fi
    # shellcheck disable=SC2154
    if [[ -n "${old_https_proxy}" ]]; then
        export https_proxy="${old_https_proxy}"
    fi
    # shellcheck disable=SC2154
    if [[ -n "${old_no_proxy}" ]]; then
        export no_proxy="${old_no_proxy}"
    fi
}


function main() {
    ARTIFACTS_RAW="${ARTIFACTS_RAW:-"${*}"}"
    # converts a string of a,b,c,... to array of (a b c ...)
    IFS=',' read -ar ARTIFACTS_ARR <<< "${ARTIFACTS_RAW}"
    mypushd "${PWD}"
    backup_env
    load_config "${CONFIGS[@]}"
    export OLD_PATH="${PATH}"
    # shellcheck disable=SC2153
    lazy_setup_jfrog_cli "${JCLI_URL}"
    lazy_config_jfrog_cli "${ARTIFACTORY_ID}"
    data_dir="$( gen_datadir "${HOME}" "jfrog" )"
    echo "Generated data_dir=${data_dir}"
    download_things "${data_dir}"
    upload_things "${data_dir}"
    cleanup "${data_dir}"
    restore_env
    mypopd
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
    exit $?
fi
