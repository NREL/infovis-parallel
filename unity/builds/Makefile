#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake androidsdk


tango:
	adb devices
	adb install -r infovis-tango.apk


.SUFFIXES:

.PHONY: tango
