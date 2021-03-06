#!/bin/bash

REMOTE=$2
CFG=$1
EXE=dist/build/infovis-parallel/infovis-parallel

echo Configutation: $CFG

for p in `sed -n -e '/port/ {s/^.*port.*['"'"'"]\(.*\)['"'"'"].*$/\1/ ; p}' $CFG`
do
  echo Starting slave on port $p . . .
  $EXE planes-cave --port=$p &
  sleep 1s
done

wait
