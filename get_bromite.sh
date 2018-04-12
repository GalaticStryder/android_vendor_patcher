#!/bin/bash

BROMITE_TAG="65.0.3325.218"
BROMITE_ARCH="arm64"
BROMITE_FLAVOR="ChromeModernPublic"
BROMITE_URL="https://github.com/bromite/bromite/releases/download/${BROMITE_TAG}/${BROMITE_ARCH}_${BROMITE_FLAVOR}.apk"
BROMITE_PATH="prebuilt/app/Bromite.apk"
BROMITE_SIZE="101262082"

function get_bromite {
  if [ "$1" = "--force" ] || [ "$1" = "-F" ]; then
    if [ -f $BROMITE_PATH ]; then
      rm -f $BROMITE_PATH
    fi;
  fi;
  if [ -f $BROMITE_PATH ]; then
    SIZE=$(du -sb $BROMITE_PATH | awk '{ print $1 }')
    if [ $SIZE -lt $BROMITE_SIZE ]; then
      curl -s -L -C - $BROMITE_URL -o $BROMITE_PATH
    fi;
  else
    curl -s -L $BROMITE_URL -o $BROMITE_PATH
  fi;
}
get_bromite $1
