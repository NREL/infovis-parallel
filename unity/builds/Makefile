#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake androidsdk


oculus:
	adb devices
	adb install -r infovis-oculus.apk

tango:
	adb devices
	adb install -r infovis-tango.apk

linux:
	tar cf infovis-linux.tar infovis-linux{.x86_64,_Data}
	xz -9f infovis-linux.tar 

macosx:
	tar cf infovis-macosx.tar infovis-macosx{,.app}
	xz -9f infovis-macosx.tar 


.SUFFIXES:

.PHONY: oculus linux macosx
