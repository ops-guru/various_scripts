#!/usr/bin/env bash
# vim: ts=4 sw=4 et

type -p curl 2> /dev/null
RETVAL=$?
if [[ "${RETVAL}" -ne 0 ]]; then 
    echo "Please install curl and rerun this script"
    exit 0
fi

python -c 'import get_latest_version' 2> /dev/null
RETVAL=$?
if [[ "${RETVAL}" -ne 0 ]]; then 
    echo "Please install packages from ./requirements.txt and rerun this script"
    exit 0
fi

JENKINS_CHANNEL="${JENKINS_CHANNEL:-"weekly"}"
JENKINS_VERSION="${JENKINS_VERSION:-$( ./get_latest_version.py -c "${JENKINS_CHANNEL}" )}"
JENKINS_URL="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war"
JENKINS_UID="1000"
JENKINS_GID="1000"

declare -a SHA_COMMAND=("sha256sum")

type "${SHA_COMMAND[@]}" 2> /dev/null || SHA_COMMAND=("shasum" "-a" "256")
curl \
    -fsSL "${JENKINS_URL}" \
    -o "jenkins.war"
JENKINS_SHA="$( "${SHA_COMMAND[@]}" "jenkins.war" | cut -d' ' -f1 )"

echo "JENKINS_VERSION=${JENKINS_VERSION}"
echo "SHA_COMMAND=${SHA_COMMAND[*]}"
echo "JENKINS_SHA=${JENKINS_SHA}"

if [[ $( id -u ) -eq "${JENKINS_UID}" ]]; then
	JENKINS_UID="${JENKINS_UID}0"
	JENKINS_GID="${JENKINS_GID}0"
fi

JENKINS_DOCKER_REPO="${JENKINS_DOCKER_REPO:-"git@github.com:jenkinsci/docker.git"}"

git clone "${JENKINS_DOCKER_REPO}"

pushd "${PWD}" || { echo "Failed to pushd $PWD"; exit 1; }
cd docker || { echo "Failed to chdir to docker"; exit 1; }
docker build \
	--build-arg JENKINS_VERSION="${JENKINS_VERSION}" \
	--build-arg JENKINS_SHA="${JENKINS_SHA}" \
	--build-arg uid="${JENKINS_UID}" \
	--build-arg gid="${JENKINS_GID}" \
	--network=host \
	--tag "jenkins/jenkins:local" \
	.

popd || { echo "FATAL: cannot return to folder we came from"; exit 1; } 



