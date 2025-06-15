#!/bin/bash
jq -r '. as $root |
       path(..) | . as $path |
       $root | getpath($path) as $value |
       select($value | scalars) |
       ([$path[] | @json] | join(".")) + " = " + ($value | @json)'
