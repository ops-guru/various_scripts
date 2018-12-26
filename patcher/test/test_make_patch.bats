#!/usr/bin/env bats
export LEFT_ARCHIVE="left.tar.gz"
export RIGHT_ARCHIVE="right.tar.gz"
export EXCLUDES=("pontis.repositories")
export INT_DIR="asdf"
load ../make_patch "${LEFT_ARCHIVE}" "${RIGHT_ARCHIVE}"

function setup() {
	# log "in setup()"
	cd data
}


function teardown() {
	# log "in teardown()"
	rm -fr ./"${INT_DIR}"*
	cd ../
}

@test "test make_patch generates a patch" {
	# statements
	# LEFT_ARCHIVE="left.tar.gz"
	# RIGHT_ARCHIVE="right.tar.gz"
	# EXCLUDES=("pontis.repositories")
	run make_patch
	[ "$status" -eq 0 ]
	[[ -f "upgrade.patch" ]]
}

@test "test upgrade.patch brings us to the desired effect" {
	# statements
	run tar zxf left.tar.gz
	[ "$status" -eq 0 ]
	cd "${INT_DIR}"
	run patch -p1 < ../upgrade.patch
	[ "$status" -eq 0 ]
	cd ../
	run mv "${INT_DIR}"{,-postpatch}
	[ "$status" -eq 0 ]
	run tar zxf right.tar.gz
	[ "$status" -eq 0 ]
	run diff -u -r "${INT_DIR}"{,-postpatch}
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "" ]
	run rm -fr ./upgrade.patch
}