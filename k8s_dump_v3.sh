#!/bin/bash

UTILS="${HOME}/bin"
PATH="$PATH:${UTILS}"

#set -e

hash kubectl
hash split_json.py

if [ $# -ne 1 ]; then
	echo choose contexts as a first argument
	kubectl config get-contexts
	exit 1
else
	CONTEXT=$1
fi

get_non_namespaced() {
  NONAMESPACED=$(kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list --namespaced=false | awk '{ print $1 }' | sort | uniq )
  echo No Namespaced :  $NONAMESPACED
  echo "---------------------------------------"
  mkdir NONAMESPACED
  pushd NONAMESPACED
  echo working on non namespace
  for RESOURCE in $NONAMESPACED ; do
        echo "     ${RESOURCE}"
        kubectl --context "${CONTEXT}"  get $RESOURCE -o json > "${RESOURCE}".json
	split_json2.py ${RESOURCE}.json
  done
  popd 
}

get_namespaced_resources() {
  for RESOURCE in ${NAMESPACED} ; do
  	echo $RESOURCE
 	kubectl --context "${CONTEXT}"  get $RESOURCE -A -o json > ${RESOURCE}.json
	split_json.py ${RESOURCE}.json &
  done
  wait
} 

get_namespaced() {
  NAMESPACED=$(kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list --namespaced=true | awk '{ print $1 }' | sort | uniq )
  echo Namespaced :  $NAMESPACED
  mkdir NAMESPACED
  pushd NAMESPACED
  get_namespaced_resources "$NAMESPACED" &
  wait
  popd
}

# echo 'not including following:'
# kubectl api-resources --no-headers=true -o wide | grep -v -e get -e list

DATE=$(date +%F_%T)
mkdir -p "K8S_DUMP/${CONTEXT}/${DATE}"
pushd "K8S_DUMP/${CONTEXT}/${DATE}"


get_non_namespaced
get_namespaced


