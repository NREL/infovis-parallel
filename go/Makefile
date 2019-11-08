#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p go


SRCS=$(wildcard main.go infovis/*.go)


all: go-infovis


go-infovis: $(SRCS)
	GOPATH= go build -o $@ .

clean:
	rm go-infovis

run: go-infovis
	./go-infovis

.SUFFIXES:

.PHONY: all clean run
