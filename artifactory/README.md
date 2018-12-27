# artifactory.sh

Effectively copies a list of artifacts (spread over various "source" repositories) to single target repository

## Requirements:

* `bash` (4.4 and up)
* `curl`

## Installation:

1. Clone this repository: `git clone https://github.com/ops-guru/various_scripts.git`
1. Copy `artifactory.bash` to your/system `PATH` as `artifactory.sh`
    1. Make the file executable, e.g. by `chmod +x artifactory.sh`

## Assumptions:

* artifacts are taken from the same artifactory they are uploaded to
* this is not the main tool, just a supplement to tweak things semi-manually

# Usage:

## Setup

1. Work in the folder `artifactory` of the cloned repository
1. Run: `cp {example.,}artifactory.config.sh`
    * edit the file `artifactory.config.sh` and fill in your details

## Usage:

1. Create a list of `repo/path/to/artifact1` items and store them in `ARTIFACTS_RAW` variable
1. Option#1 pass list of artifacts to the script:
```!bash
	artifactory.sh "${ARTIFACTS_RAW}"
```
1. Option#2 put list of artifacts into the configuration file `artifactory.config.sh`

## Advanced Usage:

### Working with multiple artifactories:

Assuming you have several environments you can do repeatative tasks by creating multiple config files
e.g. "production" and "test":

1. create `production.artifactory.config.sh` and `test.artifactory.config.sh`
1. to move artifacts on `production` env to its target repo:
    1. set variable `ARTIFACTS_RAW` to contain artifacts of `production`
    1. run: `ARTIFACTORY_CONFIG=production.artifactory.config.sh artifactory.sh "${ARTIFACTS_RAW}"`
1. to move artifacts on `test` env to its target repo:
    1. set variable `ARTIFACTS_RAW` to contain artifacts of `test`
    1. run: `ARTIFACTORY_CONFIG=test.artifactory.config.sh artifactory.sh "${ARTIFACTS_RAW}"`

### Working with Proxy Servers

Assuming you have non-authenticated proxy servers to work with, uncomment corressponding lines in the file.
