#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" shell.nix


SHELL=bash

IVP=infovis-parallel

KAFKA=127.0.0.1

LOGGING=Info


lemur:
	sed -e "s/localhost/$(KAFKA)/g" displays/lemur.yaml > tmp/display.yaml
	$(IVP) visualize --logging=$(LOGGING) tmp/display.yaml

asus-vg278:
	sed -e "s/localhost/$(KAFKA)/g" displays/asus-vg278.yaml > tmp/display.yaml
	$(IVP) visualize --logging=$(LOGGING) tmp/display.yaml

esif-b311:
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-0.yaml > tmp/display-0.yaml
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-1.yaml > tmp/display-1.yaml
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-2.yaml > tmp/display-2.yaml
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-3.yaml > tmp/display-3.yaml
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-4.yaml > tmp/display-4.yaml
	sed -e "s/localhost/$(KAFKA)/g" displays/esif-b311-5.yaml > tmp/display-5.yaml
	$(IVP) visualize --logging=$(LOGGING) tmp/display-0.yaml &
	$(IVP) visualize --logging=$(LOGGING) tmp/display-1.yaml &
	$(IVP) visualize --logging=$(LOGGING) tmp/display-2.yaml &
	$(IVP) visualize --logging=$(LOGGING) tmp/display-3.yaml &
	$(IVP) visualize --logging=$(LOGGING) tmp/display-4.yaml &
	$(IVP) visualize --logging=$(LOGGING) tmp/display-5.yaml &
	kafka-device-vrpn Head0@10.60.6.100          vrpn-client $(KAFKA) 9092 devices esif-head      &
	kafka-device-vrpn Joystick0@10.60.6.100      vrpn-client $(KAFKA) 9092 devices esif-joystick0 &
	kafka-device-vrpn JoystickA@10.60.6.100:3884 vrpn-client $(KAFKA) 9092 devices esif-joystickA &
	wait

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
	sed -e "s/localhost/$(KAFKA)/g" interpretations/joystick.yaml > tmp/ijoystick.yaml
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

topics:
	kafka-topics.sh --zookeeper $(KAFKA):2181 --topic devices   --create --partitions 1 --replication-factor 1
	kafka-topics.sh --zookeeper $(KAFKA):2181 --topic requests  --create --partitions 1 --replication-factor 1
	kafka-topics.sh --zookeeper $(KAFKA):2181 --topic responses --create --partitions 1 --replication-factor 1


.SUFFIXES:

.PHONY: laptop desktop esif-b311 events joystick spacenav keyboard complex example topics
