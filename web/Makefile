#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p nodejs


SRCS=$(wildcard src/*.js src/*/*.js)


all: controller.js

controller.js: $(SRCS)
	npx webpack

clean:
	rm controller.js

lint: controller.js
	npx eslint -c eslint.json src/{configuration,connection,controller,transport,visualizer,rendering/*}.js

install:
	npm install webpack webpack-cli


.SUFFIXES:

.PHONY: all clean install lint
