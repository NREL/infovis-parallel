#!/usr/bin/env nix-shell
#!nix-shell -i bash -p androidsdk

adb devices

adb install -r infovis-oculus.apk
