#!/bin/bash

if [ -d $1 -a -d $2 ] ; then
  echo ok
else
  echo not a dir
fi

DIR1=$1
DIR2=$2
echo $DIR1 $DIR2
cp -a "$DIR1" "flat_${DIR1}"
LIST=$(find "flat_${DIR1}" -type f -name "*.json")
for i in $LIST; do
     echo $i
     /Users/none/GIT/kctl-x/full_path_name.py "$i" > "$i.fjson"
     rm "$i"
done

cp -a "$DIR2" "flat_${DIR2}"
LIST=$(find "flat_${DIR2}" -type f -name "*.json")
for i in $LIST; do
     echo $i
     /Users/none/GIT/kctl-x/full_path_name.py "$i" > "$i.fjson"
     rm "$i"
done

set -x
diff -ur "flat_${DIR1}" "flat_${DIR2}" | grep -e ^+ -e ^- -e ^Only

