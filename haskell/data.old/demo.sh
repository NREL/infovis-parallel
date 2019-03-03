#!/bin/bash

kafka-device-spacenav laptop/spacenav.yaml &
kafka-device-spacenav laptop/joystick.yaml &

../dist/build/infovis-parallel/infovis-parallel +RTS -N6 -RTS solo ENB2012.yaml presentation.yaml demo/world.yaml demo/input.yaml &

wait
