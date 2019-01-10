#!/usr/bin/env bash
# vim: ts=4 sw=4 et
JENKINS_UID="1000"
JENKINS_GID="1000"
JENKINS_CHANNEL="${JENKINS_CHANNEL:-"weekly"}"
JENKINS_VERSION="${JENKINS_VERSION:-"2.157"}"
JENKINS_DOCKER_REPO="${JENKINS_DOCKER_REPO:-"git@github.com:jenkinsci/docker.git"}"
JENKINS_DOCKER_IMAGE_TAG="${JENKINS_DOCKER_IMAGE_TAG:-"jenkins/jenkins:local"}"
JENKINS_RUNNER_SCRIPT="${JENKINS_RUNNER_SCRIPT:-"jenkins_runner"}"
declare -a SHA_COMMAND=("sha256sum")
type "${SHA_COMMAND[@]}" 2> /dev/null || SHA_COMMAND=("shasum" "-a" "256")
declare -a MANDATORY_TOOLS=(
    docker
    curl
)

source "./jenkins_runner"

function check_tools() {
    local -a tools
    local tool
    local retval
    tools=("${@}")
    for tool in "${tools[@]}"; do
        type -p "${tool}" 2> /dev/null >/dev/null
        retval=$?
        if [[ "${retval}" -ne 0 ]]; then 
            log.info "Please install ${tool} and then rerun this script"
            exit 0
        fi
    done
    python -c 'import get_latest_version' 2> /dev/null
    retval=$?
    if [[ "${retval}" -ne 0 ]]; then 
        log.info "Please run: pip install -r ./requirements.txt and then rerun this script"
        exit 0
    fi
    return 0
}


function find_latest_jenkins_and_hash() {
    local \
        latest_jenkins_version
    local -a cmd
    latest_jenkins_version="$( ./get_latest_version.py -c "${JENKINS_CHANNEL}" )"
    if [[ "${latest_jenkins_version}" != "${JENKINS_VERSION}" ]]; then
        JENKINS_VERSION="${latest_jenkins_version}"
    fi
    JENKINS_URL="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war"
    cmd=(curl '-fsSL')
    cmd+=("${JENKINS_URL}")
    cmd+=('-o' "jenkins.war")
    log.debug "About to run: ${cmd[*]}"
    "${cmd[@]}"
    JENKINS_SHA="$( "${SHA_COMMAND[@]}" "jenkins.war" | cut -d' ' -f1 )"
    log.info "JENKINS_VERSION=${JENKINS_VERSION}"
    log.info "SHA_COMMAND=${SHA_COMMAND[*]}"
    log.info "JENKINS_SHA=${JENKINS_SHA}"
}

function lazy_adjust_ids() {
    if [[ $( id -u ) -eq "${JENKINS_UID}" ]]; then
        JENKINS_UID="${JENKINS_UID}0"
        JENKINS_GID="${JENKINS_GID}0"
    fi
}


function docker_image_builder() {
    local -a cmd
    pushd "${PWD}" || { log.error "Failed to pushd $PWD"; exit 1; }
    git clone "${JENKINS_DOCKER_REPO}"
    cd docker || { log.error "Failed to chdir to docker"; exit 1; }

    cmd=(docker build)
    cmd+=("--build-arg" "JENKINS_VERSION=${JENKINS_VERSION}")
    cmd+=("--build-arg" "JENKINS_SHA=${JENKINS_SHA}")
    cmd+=("--build-arg" "uid=${JENKINS_UID}")
    cmd+=("--build-arg" "gid=${JENKINS_GID}")
    cmd+=("--network=host")
    cmd+=("--tag" "${JENKINS_DOCKER_IMAGE_TAG}")
    cmd+=(".")
    log.debug "About to run: ${cmd[*]}"
    "${cmd[@]}"
    popd || { log.error "cannot return to folder we came from"; exit 1; } 
}


function install_runner_script() {
    local \
        target
    target="${1:-"${HOME}/bin"}"
    mkdir -p "${target}"
    cp "${JENKINS_RUNNER_SCRIPT}" "${target}/"
    chmod +x "${target}/${JENKINS_RUNNER_SCRIPT}"
}

function main() {
    check_tools "${MANDATORY_TOOLS[@]}"
    find_latest_jenkins_and_hash
    lazy_adjust_ids
    docker_image_builder
    install_runner_script "${HOME}/.local/bin"
    rm -fr "jenkins.war"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
fi
