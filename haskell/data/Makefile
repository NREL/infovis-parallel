#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" shell.nix


SHELL=bash

IVP=../dist/build/infovis-parallel/infovis-parallel

LOGGING=Info


laptop:
	$(IVP) visualize --logging=$(LOGGING) visualize/laptop.yaml

events:
	$(IVP) events --logging=$(LOGGING) forward/{glut,spacenav,joystick,keyboard}.yaml

spacenav:
	kafka-device-spacenav interpretation/spacenav.yaml

joystick:
	kafka-device-joystick interpretation/joystick.yaml

example:
	$(IVP) send --logging=$(LOGGING) ../../protobuf/examples/{axes,corner-points,helices,rectangles}.pbb


.SUFFIXES:

.PHONY: laptop events joystick spacenav example
