#!/usr/bin/env python3.10
import sys
import json
import yaml
import os


if len(sys.argv) > 1 :
   data=json.load(open(sys.argv[1]))
elif len(sys.argv) == 1 :
   data=json.loads(sys.stdin.read())
for item in data['items'] :
    name=item['metadata']['name']
    kind=item['kind']
    if not os.path.exists(kind) :
        os.mkdir( kind)
    f = open( kind + "/" + name + ".yaml", "a")
    f.write(yaml.dump(item, default_flow_style=False))
    f.close()
    f = open( kind + "/" + name + ".json", "a")
    f.write(json.dumps(item))
    f.close()



