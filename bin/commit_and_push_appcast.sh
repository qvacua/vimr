#!/bin/bash

set -e

BRANCH=$1
COMPOUND_VERSION=$2
IS_SNAPSHOT=$3
UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE=$4

if [ "${IS_SNAPSHOT}" = true ] ; then
    cp ./build/Build/Products/Release/appcast_snapshot.xml .
else
    cp ./build/Build/Products/Release/appcast.xml .
fi

if [ "${IS_SNAPSHOT}" = false ] && [ "${UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE}" = true ] ; then
    cp appcast.xml appcast_snapshot.xml
fi

echo "### Commiting and pushing appcast(s) to ${BRANCH}"

git add appcast*
git commit -S -m "Bump appcast(s) to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"

