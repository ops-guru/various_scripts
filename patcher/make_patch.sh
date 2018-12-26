#!/usr/bin/env bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd  )"
source make_patch.bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "${@}"
	exit $?
fi
