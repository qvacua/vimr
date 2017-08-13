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

echo "### Commiting and pushing appcast to ${BRANCH}"

git commit -S -am "Bump appcast to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"

if [ "${IS_SNAPSHOT}" = false ] && [ "${UPDATE_SNAPSHOT_APPCAST_FOR_RELEASE}" = true ] ; then
    echo "### Committing and pushing release appcast to develop"
    git reset --hard @
    git fetch origin
    git checkout -b for_appcast origin/develop
    git merge --ff-only for_build
    cp appcast.xml appcast_snapshot.xml
    git commit appcast_snapshot.xml -m "Update appcast_snapshot with version ${COMPOUND_VERSION}"
    git push origin HEAD:develop
fi
