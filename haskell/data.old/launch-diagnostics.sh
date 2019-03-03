#!/bin/bash

CFG="$* diagnostics/world.yaml diagnostics/input.yaml"
EXE=../dist/build/infovis-parallel/infovis-parallel

echo Configutation: $CFG

for p in 44445 44446 44447 44448 44449 44450
do
  echo Starting slave on port $p . . .
  $EXE slave --port=$p &
  sleep 1s
done

sleep 1s

echo Starting master on port 44444 . . .
$EXE master $CFG

wait
