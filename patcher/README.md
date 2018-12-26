# make patch

creates a patch to upgrade archive from one state to another

## assumptions

* archive unpacks into 1 directory
* inside the unpacked directory there may be some directories at the top level you want to ignore

## requirements:

* bash (4.4 and up)
* git

# usage:

1. learn about the archive and map ALL directories you want to ignore
1. launch the script `/path/to/make_patch.sh archive-1.tar.gz archive-2.tar.gz dir1,dir2,dir3`

