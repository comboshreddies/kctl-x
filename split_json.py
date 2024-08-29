#!/usr/bin/env python3
import sys
import json
import yaml
import os


if len(sys.argv) > 1 :
   data=json.load(open(sys.argv[1]))
elif len(sys.argv) == 1 :
   data=json.loads(sys.stdin.read())
for item in data['items'] :
    namespace=item['metadata']['namespace']
    name=item['metadata']['name']
    kind=item['kind']
    if not os.path.exists(namespace) :
        os.mkdir(namespace)
    if not os.path.exists(namespace + "/" + kind) :
        os.mkdir(namespace + "/" + kind)
    f = open(namespace + "/" + kind + "/" + name + ".yaml", "a")
    f.write(yaml.dump(item, default_flow_style=False))
    f.close()
    f = open(namespace + "/" + kind + "/" + name + ".json", "a")
    f.write(json.dumps(item))
    f.close()



