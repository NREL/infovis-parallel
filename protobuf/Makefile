#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake protobuf


EXAMPLES=$(addsuffix .pbb,$(basename $(wildcard examples/*.pbt)))


all: examples ../unity/Assets/Infovis/Protobuf.cs

examples: $(EXAMPLES)


%.cs: infovis.proto3
	protoc --csharp_out . $<
	mv Infovis.cs $@

%.pbb : %.pbt infovis.proto3
	protoc --encode=Infovis.Request infovis.proto3 < $< > $@


.SUFFIXES:

.PHONY: examples
