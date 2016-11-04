#!/bin/bash

set -e

echo "### Preparing repositories"

# delete all (local) tags
git tag | xargs git tag -d

pushd neovim
git tag | xargs git tag -d
popd

# delete all (local) branches
git for-each-ref --format="%(refname:strip=2)" refs/heads/ | xargs git branch -D
git checkout -b for_build

# update neovim
git submodule update --init --force

echo "### Prepared repositories"
