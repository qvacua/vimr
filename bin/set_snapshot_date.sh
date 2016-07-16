#!/bin/bash

NEW_MARKETING_VERSION=$(agvtool what-marketing-version | tail -n 1 | sed -E 's/.*of "(.*)" in.*/\1/' | sed -E "s/(.*)-SNAPSHOT-.*/\1-SNAPSHOT-$(date +%Y%m%d.%H%M)/")

agvtool new-marketing-version $NEW_MARKETING_VERSION

echo $NEW_MARKETING_VERSION

