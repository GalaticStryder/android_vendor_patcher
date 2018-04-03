#!/bin/bash
#
SCRIPT_VERSION="5.0"
# sync
# build

#red='\033[01;31m'
#green='\033[01;32m'
#yellow='\033[01;33m'
#blue='\033[01;34m'
#blink_red='\033[05;31m'
#blink_green='\033[05;32m'
#blink_yellow='\033[05;33m'
#blink_blue='\033[05;34m'
#restore='\033[0m'

clear

#TARGET=${1};
#devrr[0]="zl1" # Le Pro3
#devrr[1]="x2"  # Le Max2
#devrand=$[$RANDOM % ${#devrr[@]}]
#if [ -z "$TARGET" ]; then
	#echo -e ${yellow}"No target argument was passed, randomly picking one..."${restore}
	#TARGET="${devrr[$devrand]}"
	#echo -e ${green}"Lucky boy! Your target is the $TARGET..."${restore}
	#echo ""
#fi;

MAIN_FOLDER=`pwd`
PATCHER_FOLDER="$MAIN_FOLDER/vendor/patcher"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
WEB_MANIFEST="https://gist.githubusercontent.com/GalaticStryder/8e5a48db297488b7d4086a88daf71f28/raw/local_manifest.xml"
LOCAL_MANIFEST=".repo/local_manifests/local_manifest.xml"

function setup {
  source build/envsetup.sh
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

if [ ! -z $(pwd | grep patcher) ]; then
  echo "You cannot run this script out of the tree root!"
  cp main.sh ../../
  exit 1
fi;

setup
# sync
echo "Tip: Commit all your local changes before syncing..."
run_unpatcher
repo_sync
get_repopick
get_bromite
run_patcher
