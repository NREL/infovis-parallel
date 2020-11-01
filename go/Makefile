#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p go golint


SRCS=$(wildcard main.go infovis/*.go infovis/*/*.go)


all: go-infovis


go-infovis: $(SRCS)
	GOPATH= go build -o $@ .

setcap: go-infovis
	sudo setcap 'cap_net_bind_service=+ep' $@

lint: $(SRCS)
	GOPATH= golint main.go
	GOPATH= golint infovis/*.go
	GOPATH= golint infovis/export/*.go
	GOPATH= golint infovis/protobuf/*.go
	GOPATH= golint infovis/switchboard/*.go

tidy: $(SRCS)
	GOPATH= go mod tidy
	GOPATH= go mod verify

clean:
	rm go-infovis

run: go-infovis
	./go-infovis

.SUFFIXES:

.PHONY: all clean lint run setcap
