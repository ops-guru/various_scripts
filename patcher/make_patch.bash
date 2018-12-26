#!/usr/bin/env bash

# vim: ts=4 sw=4 et

## Global variables
LEFT_ARCHIVE="${1?cannot continue without LEFT_ARCHIVE}"
RIGHT_ARCHIVE="${2?cannot continue without RIGHT_ARCHIVE}"
EXCLUDES_RAW="${3?"cannot continue without EXCLUDES_RAW variable containing comma separated dirs we ignore to patch"}"
declare -a EXCLUDES
IFS=',' read -r -a EXCLUDES <<< "${EXCLUDES_RAW}"

# functions:

function join_by() { local IFS="$1"; shift; echo "$*"; }

function cleanup_dirs() {
	local -a except_dirs
	except_dirs=('\.$')
	if [[ "${#@}" -ne 0 ]]; then
		except_dirs+=("${@}")
	fi
	echo "INFO: clean up all dirs in current working dir, except: ${except_dirs[@]}"
	find . -maxdepth 1 -type d | grep -Evw "$(join_by '|' "${except_dirs[@]}" )" | xargs rm -vfr
	return $?
}

function cleanup_files() {
	local -a except_files
	local -a cmd
	except_files=()
	if [[ "${#@}" -ne 0 ]]; then
		except_files+=("${@}")
	fi
	echo "INFO: clean up all files in current working dir, except: ${except_files[@]}"
	cmd=("")
	if [[ "${#except_files[@]}" -eq 0 ]]; then
		find . -maxdepth 1 -type f  | xargs rm -vfr
		retval=$?
	else
		find . -maxdepth 1 -type f  | grep -Evw "$(join_by '|' "${except_files[@]}" )" | xargs rm -vfr
		retval=$?		
	fi
	return "${retval}"
}


function setup_git_repo() {

	{
		for dpath in "${EXCLUDES[@]}"; do
			echo "./${dpath}"
		done
	} >> .gitignore

	git init

}

function commit_current_dir() {
	local tag
	tag="${1?"cannot continue without target tag"}"
	git add -A .
	git commit -s -m "${tag} commit"
	git tag -a "${tag}" -m "${tag}"
}

function make_patch() {

	local \
		internal_dir \
		ltag \
		rtag \
		curr_dir

	cleanup_dirs
	cleanup_files "${LEFT_ARCHIVE}" "${RIGHT_ARCHIVE}"
	curr_dir="${PWD}"
	pushd "${curr_dir}"
	# unpack left file
	tar zxf "${LEFT_ARCHIVE}"
	internal_dir="$( find . -maxdepth 1 -type d | grep -Evw "\.$" )"
	# dive in
	cd "${internal_dir}" || { echo "FATAL: cannot 'cd ${internal_dir}'"; exit 1; }
	# setup repo with gitignore
	setup_git_repo
	ltag="$( basename "${LEFT_ARCHIVE}" )"
	# save left into git
	commit_current_dir "${ltag}"
	# delete files of left hand
	cleanup_dirs ".git"
	cleanup_files ".gitignore"
	# up
	cd ../
	# unpack right file
	tar zxf "${RIGHT_ARCHIVE}"
	# dive in
	cd "${internal_dir}" || { echo "FATAL: cannot 'cd ${internal_dir}'"; exit 1; }
	rtag="$( basename "${RIGHT_ARCHIVE}" )"
	commit_current_dir "${rtag}"
	git diff "${LEFT_ARCHIVE}".."${RIGHT_ARCHIVE}" > "${curr_dir}/upgrade.patch"
	popd
	return $?
}



function main() {
	make_patch
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "${@}"
	exit $?
fi
