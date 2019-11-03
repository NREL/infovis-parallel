#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p nodejs html-tidy


SRCS=$(wildcard src/*.js src/*/*.js)


all: controller.js

controller.js: $(SRCS)
	npx webpack

clean:
	rm controller.js

lint: model.html controller.js
	npx eslint -c eslint.json src/{configuration,connection,controller,transport,visualizer,rendering/*}.js
	tidy -quiet -o /dev/null model.html

deploy: controller.js
	gsutil -q -m cp -r -a public-read model.html view.css controller.js src images gs://visualize.functionally.io/

install:
	npm install webpack webpack-cli


.SUFFIXES:

.PHONY: all clean install lint deploy
