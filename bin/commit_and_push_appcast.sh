#!/bin/bash

BRANCH=$1
COMPOUND_VERSION=$2
IS_SNAPSHOT=$3

if [ "${IS_SNAPSHOT}" = true ] ; then
    cp ./build/Release/appcast_snapshot.xml .
else
    cp ./build/Release/appcast.xml .
    cp ./build/Release/appcast.xml ./appcast_snapshot.xml
fi

echo "### Commiting and pushing appcast"

git commit -am "Bump appcast to ${COMPOUND_VERSION}"
git push origin HEAD:"${BRANCH}"
