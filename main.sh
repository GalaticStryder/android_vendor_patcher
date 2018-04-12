#!/bin/bash
#
# Just a simple effortlessly way to sync, clean and build my custom
# LineageOS 15.1 or TWRP recovery variant.
# TODO: Add updater URI generator and signing mechanisms.
#

function usage {
  echo "Usage:"
  echo ""
  echo "This script receives three kinds of MODE inputs:"
  echo "sync  - to pull the latest source into your local machine;"
  echo "clean - to clean up the output directory;"
  echo "build - to build boot/recovery image or OTA package."
  echo "The last one - BUILD - is more flexible, you can add all your wishes there:"
  echo "     boot - to generate the Kernel boot.img;"
  echo "     recovery - to generate the TWRP recovery.img;"
  echo "     bacon - to generate the final OTA package zip file."
  echo ""
  echo "Example: ./main.sh sync clean build bacon."
  echo "This will be what you'll running most of the time..."
}

mode=("$@")
if [ -z "$mode" ]; then
  usage
  exit
fi;

clear

target[0]="zl1" # Le Pro3
target[1]="x2"  # Le Max2

MAIN_FOLDER=`pwd`
PATCHER_FOLDER="$MAIN_FOLDER/vendor/patcher"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
WEB_MANIFEST="https://gist.githubusercontent.com/GalaticStryder/8e5a48db297488b7d4086a88daf71f28/raw/local_manifest.xml"
WEB_REPOPICK="https://gist.githubusercontent.com/GalaticStryder/aded34e7a3f8abfa48c9471e3ff6d3df/raw/repopick.txt"
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
  repo sync $THREAD
}

function get_repopick {
  curl -s -L $WEB_REPOPICK -o $PATCHER_FOLDER/repopick.txt
  for i in $(cat $PATCHER_FOLDER/repopick.txt | grep -v "#"); do
    repopick $i -q
  done
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
  shift
  run_unpatcher
  repo_sync
  get_repopick
  get_bromite
  run_patcher
fi;
if [[ "${mode[@]}" =~ "clean" ]]; then
  shift
  mka clean
fi;
if [[ "${mode[@]}" =~ "build" ]]; then
  shift
  pick_target
  if [[ "$@" =~ "boot" ]]; then
    echo "Building Kernel boot image..."
    breakfast $TARGET user
    mka bootimage
  fi
  if [[ "$@" =~ "recovery" ]]; then
    echo "Building TWRP recovery image..."
    WITH_TWRP=true breakfast $TARGET userdebug
    WITH_TWRP=true mka recoveryimage
  fi
  if [[ "$@" =~ "bacon" ]]; then
    echo "Building OTA package zip file..."
    breakfast $TARGET user
    mka bacon
  fi
fi;

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
