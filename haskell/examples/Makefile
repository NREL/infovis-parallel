#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" shell.nix


SHELL=bash

IVP=../dist/build/infovis-parallel/infovis-parallel

KAFKA=localhost

LOGGING=Info


laptop:
	sed -e "s/localhost/$(KAFKA)/g" displays/laptop.yaml > tmp/display.yaml
	$(IVP) visualize --logging=$(LOGGING) tmp/display.yaml

events:
	sed -e "s/localhost/$(KAFKA)/g" forward/glut.yaml     > tmp/glut.yaml
	sed -e "s/localhost/$(KAFKA)/g" forward/spacenav.yaml > tmp/spacenav.yaml
	sed -e "s/localhost/$(KAFKA)/g" forward/joystick.yaml > tmp/joystick.yaml
	sed -e "s/localhost/$(KAFKA)/g" forward/keyboard.yaml > tmp/keyboard.yaml
	$(IVP) events --logging=$(LOGGING) --host=$(KAFKA) tmp/{glut,spacenav,joystick,keyboard}.yaml

spacenav:
	sed -e "s/localhost/$(KAFKA)/g" interpretations/spacenav.yaml > tmp/ispacenav.yaml
	kafka-device-spacenav tmp/ispacenav.yaml

joystick:
	sed -e "s/localhost/$(KAFKA)/g" interpretations/spacenav.yaml > tmp/ispacenav.yaml
	kafka-device-joystick tmp/ijoystick.yaml

keyboard:
	kafka-device-keyboard --host=$(KAFKA)

complex:
	$(IVP) present --logging=$(LOGGING) datasets/ENB2012.yaml presentations/complex.yaml
	mv grid.pbb presentations/complex-grid.pbb
	mv data.pbb presentations/complex-data.pbb
	$(IVP) send --logging=$(LOGGING) --host=$(KAFKA) presentations/complex-*.pbb

example:
	$(IVP) send --logging=$(LOGGING) ../../protobuf/examples/{axes,corner-points,helices,rectangles}.pbb


.SUFFIXES:

.PHONY: laptop events joystick spacenav keyboard example
