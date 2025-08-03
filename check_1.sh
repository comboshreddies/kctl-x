#!/bin/sh
time /bin/bash -c " _ --context miku api-resources | _ get ns | _ get {{kind}} | _ get {{kind}} {{name}} > /tmp/x 2>/dev/null"

