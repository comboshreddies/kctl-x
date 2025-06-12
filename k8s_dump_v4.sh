#!/bin/bash

UTILS="${HOME}/bin"
PATH="$PATH:${UTILS}"

set -e

hash kubectl
hash python3
hash sort
hash uniq
hash awk
hash chmod

if [ $# -ne 1 ]; then
        echo choose context as a first argument
        kubectl config get-contexts
        exit 1
else
        CONTEXT=$1
fi

TMPPY=$(mktemp)
cat > "$TMPPY" <<PYTHON3
#!/usr/bin/env python3
import sys
import json
import yaml
import os

if len(sys.argv) > 1:
    data = json.load(open(sys.argv[1]))
elif len(sys.argv) == 1:
    data = json.loads(sys.stdin.read())
for item in data["items"]:
    name = item["metadata"]["name"]
    kind = item["kind"]
    if "namespace" in item["metadata"]:
        namespace = item["metadata"]["namespace"]
        if not os.path.exists(namespace):
            os.mkdir(namespace)
        if not os.path.exists(namespace + "/" + kind):
            os.mkdir(namespace + "/" + kind)
    else:
        namespace = "."
        if not os.path.exists(kind):
            os.mkdir(kind)
    f = open(namespace + "/" + kind + "/" + name + ".yaml", "a")
    f.write(yaml.dump(item, sort_keys=False, default_flow_style=False))
    f.close()
    f = open(namespace + "/" + kind + "/" + name + ".json", "a")
    f.write(json.dumps(item, sort_keys=True))
    f.close()
PYTHON3
chmod 700 "$TMPPY"

get_non_namespaced() {
  NONAMESPACED=$(kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list --namespaced=false | awk '{ print $1 }' | sort | uniq )
  echo "---------------------------------------"
  mkdir NONAMESPACED
  pushd NONAMESPACED > /dev/null
  echo fetching non namespaced resources :
  for RESOURCE in $NONAMESPACED ; do
        echo -n "${RESOURCE} "
        kubectl --context "${CONTEXT}"  get "$RESOURCE" -o json > "${RESOURCE}.json"
        "$TMPPY" "${RESOURCE}.json" &
  done
  popd > /dev/null
}

get_namespaced_resources() {
  for RESOURCE in ${NAMESPACED} ; do
        echo -n "${RESOURCE} "
        kubectl --context "${CONTEXT}"  get "$RESOURCE" -A -o json > "${RESOURCE}.json"
        "$TMPPY" "${RESOURCE}.json" &
  done
  wait
}

get_namespaced() {
  NAMESPACED=$(kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list --namespaced=true | awk '{ print $1 }' | sort | uniq )
  echo "Namespaced :  $NAMESPACED"
  mkdir NAMESPACED
  pushd NAMESPACED > /dev/null
  echo "---------------------------------------"
  echo fetching on namespaced resources:
  get_namespaced_resources "$NAMESPACED" &
  wait
  popd > /dev/null
}

#echo "----------------------------------------"
#echo 'not including following:'
#kubectl api-resources --no-headers=true -o wide | grep -v -e get -e list
#echo "----------------------------------------"

DATE=$(date +%F_%T)
mkdir -p "K8S_DUMP/${CONTEXT}/${DATE}"
pushd "K8S_DUMP/${CONTEXT}/${DATE}" > /dev/null


get_non_namespaced
get_namespaced

echo '# Completed'
