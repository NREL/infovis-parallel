#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake protobuf go


EXAMPLES=$(addsuffix .pbb,$(basename $(wildcard examples/*.pbt)))


all: examples ../web/src/infovis.proto3_pb.js ../go/infovis/infovis.proto3.pb.go ../julia/src/Infovis.jl ../python/src/infovis/proto3_pb2.py

examples: $(EXAMPLES)

examples/bslm-%.pbt: examples/bslm.tsv.part-% examples/bslm.awk
	gawk -f examples/bslm.awk $< > $@


%.cs: infovis.proto3
	protoc --csharp_out $(dir $@) $<

%.js: infovis.proto3
	protoc --js_out import_style=commonjs,binary:$(dir $@) $<

%.go: infovis.proto3
	GOPATH=$(PWD)/tmp go get github.com/golang/protobuf/protoc-gen-go
	PATH=$(PWD)/tmp/bin:$(PATH) protoc --go_out $(dir $@) $<

%.jl: infovis.proto3
	protoc --julia_out=$(dir $@) $<

%.py: infovis.proto3
	protoc --python_out $(dir $@) $<

%.pbb : %.pbt infovis.proto3
	protoc --encode=Infovis.Request infovis.proto3 < $< > $@


.SUFFIXES:

.PHONY: examples
