#!/usr/bin/env python3
import sys
import json
import os
from importlib import util

def rec_descent(data,path):
    #print(type(data))
    if isinstance(data,dict):
        for i in data:
            if path :
                step=f'{path}.'
            else:
                step=''
            rec_descent(data[i],f'{step}"{i}"')
    elif isinstance(data,list):
        for i in range(len(data)):
            if isinstance(data[i],list) and 'name' in data[i]:
               name=data[i]['name']
               rec_descent(data[i],f'{path}.{i}[{name}]')
            else:
               rec_descent(data[i],f'{path}.{i}')
    else:
        if isinstance(data,bool):
            if data :
                print(f'{path} = true')
            else:
                print(f'{path} = false')
        else:
            if isinstance(data,int):
                print(f'{path} = {data}')
            elif isinstance(data,type(None)): 
                print(f'{path} = null') 
            else:
                print(f'{path} = "{data}"')

if len(sys.argv) == 2:
    data = json.load(open(sys.argv[1]))
elif len(sys.argv) == 1:
    data = json.loads(sys.stdin.read())

rec_descent(data,"")

