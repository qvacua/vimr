#!/bin/bash

# For building binaries for Yosemite, 10.10.x.

set -e

./bin/prepare_repositories.sh
./bin/clean_old_builds.sh
./bin/build_vimr.sh true
