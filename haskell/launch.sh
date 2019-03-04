#!/usr/bin/env nix-shell
#!nix-shell -i bash shell.nix

IVP=dist/build/infovis-parallel/infovis-parallel

kafka-device-joystick data/interpretation/joystick.yaml &

kafka-device-spacenav data/interpretation/spacenav.yaml &

$IVP visualize data/visualize/laptop.yaml &

sleep 5s

$IVP events data/forward/{glut,spacenav,joystick,keyboard}.yaml &

$IVP send ../protobuf/examples/{axes,corner-points,helices,rectangles}.pbb &

wait
