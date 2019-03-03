#!/usr/bin/env nix-shell
#!nix-shell -i bash shell.nix

IVP=dist/build/infovis-parallel/infovis-parallel

kafka-device-joystick data/interpretation/spacenav.yaml &

kafka-device-spacenav data/interpretation/joystick.yaml &

$IVP visualize data/visualize/laptop.yaml &

$IVP events data/forward/{glut,spacenav,joystick,keyboard}.yaml &

$IVP send ../protobuf/examples/{axes,corner-points,helices,rectangles}.pbb &

wait
