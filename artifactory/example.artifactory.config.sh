#!/usr/bin/env bash
# vim: ts=4 sw=4 et
# JFrog Artifactory details
# shellcheck disable=SC2034
##################################################
# JFrog CLI details:
##################################################
JCLI_URL="${JCLI_URL:-"https://getcli.jfrog.io"}"
JCLI_PATH="${HOME}/.local/bin"
JCLI_CONFIG_FORCE="${JCLI_CONFIG_FORCE:-0}"
##################################################
# Artifactory Details:
##################################################
ARTIFACTORY_ID="Default"
ARTIFACTORY_URL="http://your-artifactory.your-domain.com:8081/artifactory"
ARTIFACTORY_USER="user_name"
ARTIFACTORY_APIKEY="**************** login -> edit profile -> copy API key ******************"
ARTIFACTORY_TARGET_REPO="your-target-repository"
##################################################
# Proxy Details:
# OPTIONAL (Will be used only while the script is running!)
##################################################
#export http_proxy="http://myproxy:8080"
#export https_proxy="https://myproxy:8443"
#export no_proxy="*.mydomain.com,10.*,192.168.*"
##################################################
# Artifacts to copy:
##################################################
ARTIFACTS_RAW="src-repo1/RPMS/pkg-2.1.0.01-2.noarch.rpm,src-repo2/subdir-x/abcd-2.0.35-26.el7.x86_64.rpm,src-repo3/subdir1/subdir2/stuff-common-4.0.2-3.el7.x86_64.rpm"
