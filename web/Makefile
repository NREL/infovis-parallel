#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p nodejs


controller.js: src/controller.js
	npx webpack

clean:
	rm controller.js

install:
	npm install webpack webpack-cli


.SUFFIXES:

.PHONY: install
