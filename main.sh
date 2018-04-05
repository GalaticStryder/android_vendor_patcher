#!/bin/bash
#
# Just a simple effortlessly way to sync and build my custom
# LineageOS 15.1 variant.
#

mode[0]="$1"
mode[1]="$2"
mode[2]="$3"
if [ -z "$mode" ]; then
  echo "This script needs at least one of the two possible inputs:"
  echo "sync - to pull the latest source into your local machine;"
  echo "build - to build the the final signed zip file."
  echo "clean - to clean up the output directory."
  echo "Or even all of them combined to do both things at once."
  exit
fi;

clear

target[0]="zl1" # Le Pro3
target[1]="x2"  # Le Max2

MAIN_FOLDER=`pwd`
PATCHER_FOLDER="$MAIN_FOLDER/vendor/patcher"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
WEB_MANIFEST="https://gist.githubusercontent.com/GalaticStryder/8e5a48db297488b7d4086a88daf71f28/raw/local_manifest.xml"
LOCAL_MANIFEST=".repo/local_manifests/local_manifest.xml"

function setup {
  source build/envsetup.sh &>/dev/null
  croot
}

function repo_sync {
  if ! [ -x "$(command -v repo)" ]; then
    echo "Could not find the repo command, aborting..."
    exit 1
  fi
  if [ -f $LOCAL_MANIFEST ]; then
    rm -f $LOCAL_MANIFEST
  fi;
  curl -s -L $WEB_MANIFEST -o $LOCAL_MANIFEST
  repo sync -f $THREAD
}

function get_repopick {
  if [ -f $PATCHER_FOLDER/repopick.txt ]; then
    for i in $(cat $PATCHER_FOLDER/repopick.txt | grep -v "#"); do
      repopick $i -q
    done
  fi
}

function get_bromite {
  cd $PATCHER_FOLDER
  ./get_bromite.sh
  cd $MAIN_FOLDER
}

function run_unpatcher {
  . $PATCHER_FOLDER/unpatcher.sh
}

function run_patcher {
  . $PATCHER_FOLDER/patcher.sh
}

function pick_target {
  echo "Which is the build target?"
  select choice in "${target[@]}"; do
    case "$choice" in
      "") break;;
      *) TARGET=$choice
        break;;
    esac
  done
}

if [ ! -z $(pwd | grep patcher) ]; then
  echo "You cannot run this script out of the tree root!"
  cp main.sh ../../
  exit 1
fi;

DATE_START=$(date +"%s")

setup
if [[ "${mode[@]}" =~ "sync" ]]; then
  echo "Tip: Commit all your local changes before syncing..."
  run_unpatcher
  repo_sync
  get_repopick
  get_bromite
  run_patcher
fi;
if [[ "${mode[@]}" =~ "clean" ]]; then
  mka clean
fi;
if [[ "${mode[@]}" =~ "build" ]]; then
  pick_target
  brunch $TARGET user
fi;

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
