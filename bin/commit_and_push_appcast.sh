#!/bin/bash

set -e

BRANCH=$1
COMPOUND_VERSION=$2
IS_SNAPSHOT=$3

if [ "${IS_SNAPSHOT}" = true ] ; then
    cp ./build/Release/appcast_snapshot.xml .
else
    cp ./build/Release/appcast.xml .
fi

echo "### Commiting and pushing appcast"

git commit -S -am "Bump appcast to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"
