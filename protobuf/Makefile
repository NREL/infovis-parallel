#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake protobuf


EXAMPLES=$(addsuffix .pbb,$(basename $(wildcard examples/*.pbt)))


all: examples ../unity/linux/Assets/Infovis/Protobuf.cs ../web/lib/pb/request.js

examples: $(EXAMPLES)

examples/bslm-%.pbt: examples/bslm.tsv.part-% examples/bslm.awk
	gawk -f examples/bslm.awk $< > $@


%.cs: infovis.proto3
	protoc --csharp_out . $<
	mv Infovis.cs $@

%.js: infovis.proto3
	protoc --js_out $(dir $@) $<

%.pbb : %.pbt infovis.proto3
	protoc --encode=Infovis.Request infovis.proto3 < $< > $@


.SUFFIXES:

.PHONY: examples
