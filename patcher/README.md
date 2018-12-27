# make_patch.sh

Creates a patch to upgrade archive from one state to another

## Requirements:

* `bash` (4.4 and up)
* `find`
* `tar`
* `git` (2.x and up)

## Installation:

1. Clone this repository: `git clone https://github.com/ops-guru/various_scripts.git`
1. Copy `make_patch.bash` to your/system `PATH` as `make_patch.sh`
    1. Make the file executable, e.g. by `chmod +x make_patch.sh`

## Assumptions:

* Archive unpacks into 1 directory
* Inside the unpacked directory there may be some directories at the top level you want to ignore
* The script is executed from a directory with only 2 archive files
    * **WARNING** other files in current directory will be deleted!

# Usage:

1. Learn about the archive and add internal directories you want to ignore to a comma (`,`) separated list
1. Run the script:
```!bash
        excluded dirs ------------------------------------+
	                                                  |
        desired state -------------------+                |
	                                 |                |
        initial state --+                |                |
	                |                |                |
	make_patch.sh archive-1.tar.gz archive-2.tar.gz dir1,dir2,dir3
```
