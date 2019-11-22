#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p nodejs html-tidy


SRCS=$(wildcard src/*.js src/*/*.js)


all: infovis.tar.gz

controller.js: $(SRCS)
	npx webpack

clean:
	rm controller.js

lint: model.html controller.js
	npx eslint -c eslint.json src/{configuration,connection,controller,transport,visualizer,rendering/*}.js
	tidy -quiet -o /dev/null model.html

infovis.tar.gz: model.html view.css controller.js lib images
	tar czf $@ $^

deploy: model.html view.css controller.js lib images
	gsutil -q -m cp -r -a public-read $^ gs://visualize.functionally.io/

serve:
	npx serve

install:
	npm install webvr-polyfill webpack webpack-cli eslint


.SUFFIXES:

.PHONY: all clean install lint deploy serve
