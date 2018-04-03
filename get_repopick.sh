#!/bin/bash

function get_repopick {
  HERE=`pwd`
  TREE="${HERE}/../.."
  cd $TREE
  if [ -f $HERE/repopick.txt ]; then
    for i in $(cat $HERE/repopick.txt | grep -v "#"); do
      repopick $i -q
    done
  fi
  cd $HERE
}
get_repopick
