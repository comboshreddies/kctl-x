#!/bin/bash
#
# environment params:
# K8S_DUMP_YAML - if set to any value and if yaml python 
#       module is available, dumps to yaml format along with json
# K8S_DUMP_KEEP_JSON_LIST - if set to any value lst.json files will not be removed
#        those files keep a list of all objects of a kind
# K8S_DUMP_TS_DIR - if set to any value overrides time stamp dir for 
#        k8s object dump (usually K8S_DUMP/<YYYY-MM-DD_hh:mm:ss>/..)
# K8S_DUMP_DIR - if set to any value overrides K8S_DUMP default
#       relative directory for kubernetes dump
#

set -e

hash kubectl
hash python3
hash sort
hash uniq
hash awk
hash chmod

# python script to split items list to single yaml/json documents
create_tmp_python() {
  TMPPY=$(mktemp)
  cat > "$TMPPY" <<PYTHON3
#!/usr/bin/env python3
import sys
import json
import os
from importlib import util

yaml_spec = util.find_spec("yaml")
yaml_found = yaml_spec is not None

if len(sys.argv) == 2:
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
    if yaml_found and os.getenv('K8S_DUMP_YAML'):
        import yaml
        f = open(namespace + "/" + kind + "/" + name + ".yaml", "a")
        f.write(yaml.dump(item, sort_keys=False, default_flow_style=False))
        f.close()
    f = open(namespace + "/" + kind + "/" + name + ".json", "a")
    f.write(json.dumps(item, sort_keys=True))
    f.close()
PYTHON3
  chmod 700 "$TMPPY"
}

get_non_namespaced() {
  NONAMESPACED=$(
    kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list \
      --namespaced=false | awk '{ print $1 }' | sort | uniq )
  echo "#--------------------------------------"
  mkdir NONAMESPACED
  pushd NONAMESPACED > /dev/null
  echo fetching non namespaced resources :
  for RESOURCE in $NONAMESPACED ; do
    echo -n "${RESOURCE} "
    kubectl --context "${CONTEXT}" get "$RESOURCE" -o json > "${RESOURCE}.lst.json"
    "$TMPPY" "${RESOURCE}.lst.json" &
  done
  wait
  for RESOURCE in $NONAMESPACED ; do
    if [ ! "$K8S_DUMP_KEEP_JSON_LIST" ] ; then
      rm "${RESOURCE}.lst.json"
    fi
  done
  popd > /dev/null
}

get_namespaced_resources() {
  for RESOURCE in ${NAMESPACED} ; do
    echo -n "${RESOURCE} "
    kubectl --context "${CONTEXT}" get "$RESOURCE" -A -o json > "${RESOURCE}.lst.json"
    "$TMPPY" "${RESOURCE}.lst.json" &
  done
  wait
  for RESOURCE in ${NAMESPACED} ; do
    if [ ! "$KEEP_JSON_LIST" ] ; then
      rm "${RESOURCE}.lst.json"
    fi
  done
}

get_namespaced() {
  NAMESPACED=$(
    kubectl --context "${CONTEXT}" api-resources --no-headers=true --verbs=get,list \
      --namespaced=true | awk '{ print $1 }' | sort | uniq )
  echo
  mkdir NAMESPACED
  pushd NAMESPACED > /dev/null
  echo "#--------------------------------------"
  echo fetching on namespaced resources:
  get_namespaced_resources "$NAMESPACED" &
  wait
  popd > /dev/null
}


if [ $# -ne 1 ]; then
        echo choose kubectl context as a first argument
        kubectl config get-contexts
        exit 1
else
        CONTEXT=$1
fi

#echo "----------------------------------------"
#echo 'following will not be fetched as there is no get or list'
#kubectl --context "${CONTEXT}" api-resources --no-headers=true -o wide | grep -v -e get -e list
#echo "----------------------------------------"

DATE=$(date +%F_%T)
TS_DIR=${K8S_DUMP_TS_DIR:-"$DATE"}
DUMPDIR=${K8S_DUMP_DIR:-"K8S_DUMP"}

echo "#--------------------------------------"
echo "# saving to ${DUMPDIR}/${CONTEXT}/${TS_DIR}"

mkdir -p "${DUMPDIR}/${CONTEXT}/${TS_DIR}"
pushd "${DUMPDIR}/${CONTEXT}/${TS_DIR}" > /dev/null


create_tmp_python
get_non_namespaced
get_namespaced

echo
echo '# Completed'
