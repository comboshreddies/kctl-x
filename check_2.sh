#!/bin/sh
time /bin/bash -c " _ --context miku api-resources | _ get {{kind}} -A | _ get {{kind}} {{name}} > /tmp/y 2>/dev/null"

