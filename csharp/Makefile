#!/usr/bin/env nix-shell
#!nix-shell -i "make -f" -p gnumake dotnet-sdk protobuf


build: src/Infovis/Protobuf.cs
	dotnet build

run: src/Infovis/Protobuf.cs
	bash -c "cd $(<D); dotnet run"

clean:
	dotnet clean
	-rm -r src/*/obj

restore:
	dotnet restore

csharp.sln:
	dotnet new sln -o ../csharp

src/Infovis/Infovis.csproj:
	dotnet new console -lang 'C#' -o $(@D)
	dotnet add $@ package Google.Protobuf --version 3.4.0
	dotnet add $@ package UnityEngine
	dotnet add $@ package WebSocketSharp --version 1.0.3-rc1
	dotnet sln add $@

src/Infovis/Protobuf.cs: ../protobuf/infovis.proto3
	protoc --csharp_out . $<
	mv Infovis.cs $@


.PHONY: build clean restore run


.SUFFIXES:
