#!/bin/bash

set -e

BRANCH=$1
COMPOUND_VERSION=$2
IS_SNAPSHOT=$3
UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE=$4

if [ "${IS_SNAPSHOT}" = true ] ; then
    cp ./build/Release/appcast_snapshot.xml .
else
    cp ./build/Release/appcast.xml .
fi

echo "### Commiting and pushing appcast"

git commit -S -am "Bump appcast to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"

if [ "${IS_SNAPSHOT}" = false ] && [ "${UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE}" = true ] ; then
    git reset --hard @
    git checkout develop
    git merge master
    cp appcast.xml appcast_snapshot.xml
    git commit appcast_snapshot.xml -m "Update appcast_snapshot with version ${COMPOUND_VERSION}"
    git push origin HEAD:develop
fi
