#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake protobuf


EXAMPLES=$(addsuffix .pbb,$(basename $(wildcard examples/*.pbt)))


all: examples ../unity/linux/Assets/Infovis/Protobuf.cs ../web/lib/infovis.proto3_pb.js

examples: $(EXAMPLES)

examples/bslm-%.pbt: examples/bslm.tsv.part-% examples/bslm.awk
	gawk -f examples/bslm.awk $< > $@


%.cs: infovis.proto3
	protoc --csharp_out . $<
	mv Infovis.cs $@

%.js: infovis.proto3
	protoc --js_out import_style=commonjs,binary:$(dir $@) $<

%.pbb : %.pbt infovis.proto3
	protoc --encode=Infovis.Request infovis.proto3 < $< > $@


.SUFFIXES:

.PHONY: examples
