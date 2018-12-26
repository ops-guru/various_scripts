# make_patch.sh

Creates a patch to upgrade archive from one state to another

## Requirements:

* `bash` (4.4 and up)
* `find`
* `tar`
* `git` (2.x and up)

## Installation:

1. copy `make_patch.bash` and `make_patch.sh` files to PATH (yours or system)
1. make sure `make_patch.sh` file is executable, e.g. by `chmod +x make_patch.sh`

## Assumptions:

* archive unpacks into 1 directory
* inside the unpacked directory there may be some directories at the top level you want to ignore
* script is executed from an empty directory with 2 archives
    * **WARNING** other files in current directory will be deleted!

# Usage:

1. learn about the archive and map ALL directories you want to ignore
1. launch the script:
```!bash
	make_patch.sh archive-1.tar.gz archive-2.tar.gz dir1,dir2,dir3
```
