#!/bin/bash
#
# Just a simple effortlessly way to sync, clean and build my custom
# LineageOS 15.1 or TWRP recovery variant.
# TODO: Add signing mechanisms and key generation.
# TODO: Add save-for-later mechanism if out-of-time.
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

if [ ! -z $(pwd | grep patcher) ]; then
  echo "You cannot run this script out of the root tree!"
  cp main.sh ../../
  echo "Copied main.sh to your root tree, now go there and run it."
  echo "cd ../../"
  exit 1
fi;

mode=("$@")
if [ -z "$mode" ]; then
  usage
  exit
fi;

clear

# Targets
target[0]="zl1" # Le Pro3
target[1]="x2"  # Le Max2

# Types
type[0]="user"
type[1]="userdebug"
type[2]="eng"

# Heroku deployment
# HEROKU_OAUTH="ASK_ME_FOR_IT"
HEROKU="https://json-lineage-v2.herokuapp.com"
WEB_MANIFEST="$HEROKU/res/local_manifest.xml"
WEB_REPOPICK="$HEROKU/res/repopick.txt"

# AOSP tree paths
MAIN_FOLDER=`pwd`
PATCHER_FOLDER="$MAIN_FOLDER/vendor/patcher"
LOCAL_MANIFEST=".repo/local_manifests/local_manifest.xml"

# Number of threads for repo sync
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

# LineageOS versioning
BRAND="lineage"
VERSION="15.1"
DATE=$(date -u +%Y%m%d)
TYPE="UNOFFICIAL"

# Github releases
REPOSITORY="lineage_releases"
TAG="dev"
# Add to ~/.bashrc and modify if you're not SuperSexy.
#export GITHUB_USERNAME="SuperSexy"
#export GITHUB_USERTOKEN="xoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxoxo"
# Generate your own token with `repo` at: https://github.com/settings/tokens

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

function target_variables {
  echo ""
  echo "Setting target ($TARGET) variables..."
  # Output folder
  PRODUCT_FOLDER="$MAIN_FOLDER/out/target/product/$TARGET"
  # Recovery file/path
  RECOVERY_NAME="recovery-${DATE}-${TARGET}"
  RECOVERY_PATH="$PRODUCT_FOLDER/$RECOVERY_NAME.img"
  # Bacon file/path
  BACON_FILE="${BRAND}-${VERSION}-${DATE}-${TYPE}-${TARGET}.zip"
  BACON_PATH="${PRODUCT_FOLDER}/${BACON_FILE}"
  echo ""
}

# curl -s https://raw.githubusercontent.com/LineageOS/hudson/master/lineage-build-targets | grep -v "#" | grep lineage-15.1 | awk '{ print $1 }'
function pick_target {
  echo "Which is the build target?"
  select choice in "${target[@]}"; do
    case "$choice" in
      "") break;;
      *) TARGET=$choice
        break;;
    esac
  done
  target_variables
}

function pick_type {
  echo "Which is the build type?"
  select choice in "${type[@]}"; do
    case "$choice" in
      "") break;;
      *) TYPE=$choice
        break;;
    esac
  done
}

# ask_release $file $tag
function ask_release {
  # Push to a different `tag` if explicitly wanted,
  # otherwise use the default tag.
  if [ ! -z $2 ]; then
    GIT_TAG=$2
  else
    GIT_TAG=$TAG
  fi;
  RELEASE=$(basename $1)
  while read -p "Push $RELEASE to Github $REPOSITORY/$GIT_TAG (Y/n)? " achoice
  do
  case "$achoice" in
    y|Y)
      echo "Pushing $RELEASE to Github $REPOSITORY/$GIT_TAG..."
      . $PATCHER_FOLDER/lineage-release.sh github_api_token=$GITHUB_USERTOKEN owner=$GITHUB_USERNAME repo=$REPOSITORY tag=$GIT_TAG filename=$1
      echo ""
      echo "...Done!"
      break
      ;;
    n|N)
      echo "Skipping $RELEASE publishment... Can you do it later?"
      break
      ;;
  esac
  done
}

function write_json {
  cat << EOF >> $TARGET.json
{"response":[{"datetime":"$(date -u +%s)","filename":"$BACON_FILE","id":"$(sha1sum $BACON_PATH | awk '{ print $1 }')","romtype": "unofficial","size":"$(du -sb $BACON_PATH | awk '{ print $1 }')","url":"https://github.com/$GITHUB_USERNAME/$REPOSITORY/releases/download/$TAG/$BACON_FILE","version":"$VERSION"}]}
EOF
}

# Needs refactoring for V2 server.
function ask_heroku {
  while read -p "Publish OTA update notification to $HEROKU (Y/n)? " achoice
  do
  case "$achoice" in
    y|Y)
      echo "Generating $TARGET.json skeleton..."
      write_json
      echo "...Done!"
      echo "Publishing $BACON_FILE to $HEROKU/$TARGET..."
      curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $HEROKU_OAUTH" -d @${TARGET}.json $HEROKU/$TARGET
      rm $TARGET.json
      echo ""
      break
      ;;
    n|N)
      echo "Skipping OTA notification publishment..."
      break
      ;;
  esac
  done
}

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
  pick_type
  if [[ "$@" =~ "boot" ]]; then
    echo "Building Kernel boot image..."
    breakfast $TARGET $TYPE
    mka bootimage
  fi
  if [[ "$@" =~ "recovery" ]]; then
    # Currently not "native" with LineageOS 15.1 tree.
    echo "WARNING: Compiling TWRP on LineageOS 15.1 tree is not recommended."
    echo "Building TWRP recovery image..."
    TYPE="eng" # Force `eng` build for TWRP.
    WITH_TWRP=true breakfast $TARGET $TYPE
    WITH_TWRP=true mka adbd recoveryimage
    if [ -f $PRODUCT_FOLDER/recovery.img ]; then
      echo "Renaming recovery.img to $RECOVERY_NAME.img..."
      cp $PRODUCT_FOLDER/recovery.img $RECOVERY_PATH
      ask_release $RECOVERY_PATH recovery
      recovery_job="succeeded"
    else
      echo "Something went wrong, $PRODUCT_FOLDER/recovery.img does not exist!"
      recovery_job="failed"
    fi
    echo "The compilation of TWRP recovery image has $recovery_job!"
  fi
  if [[ "$@" =~ "bacon" ]]; then
    echo "Building OTA package zip file..."
    breakfast $TARGET $TYPE
    mka bacon
    if [ -f $BACON_PATH ]; then
      sleep 10
      ask_release $BACON_PATH
      #ask_heroku
      bacon_job="succeeded"
    else
      echo "Something went wrong, $BACON_FILE does not exist!"
      bacon_job="failed"
    fi;
    echo "The compilation of OTA package zip file has $bacon_job!"
    # Manually push it via web app interface until V1 compatibility for posting is ready.
    echo "You can publish the update notification via $HEROKU."
  fi
fi;

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
