#!/bin/bash

BRANCH=$1
COMPOUND_VERSION=$2

cp build/Release/appcast* .

echo "### Commiting and pushing appcast"
git commit -am "Bump appcast to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"
