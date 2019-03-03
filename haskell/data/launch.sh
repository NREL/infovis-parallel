#!/usr/bin/env bash

IVP=dist/build/infovis-parallel/infovis-parallel

$IVP visualize data/visualize/laptop.yaml &

$IVP events data/forward/{glut,spacenav,joystick,keyboard}.yaml &

../../kafka-device-joystick/dist/build/kafka-device-joystick/kafka-device-joystick data/interpretation/spacenav.yaml &

../../kafka-device-spacenav/dist/build/kafka-device-spacenav/kafka-device-spacenav data/interpretation/joystick.yaml &

$IVP send ../protobuf/examples/{axes,corner-points,helices,rectangles}.pbb &

wait
