SHELL=bash


build: src/Infovis/Protobuf.cs
	dotnet build

run: src/Infovis/Protobuf.cs
	bash -c "cd $(<D); dotnet run"

clean:
	dotnet clean
	-rm -r src/*/obj

restore:
	dotnet restore

infovis-unity.sln:
	dotnet new sln -o ../infovis-unity

src/Infovis/Infovis.csproj:
	dotnet new console -lang 'C#' -o $(@D)
	dotnet add $@ package Google.Protobuf --version 3.4.0
	dotnet add $@ package UnityEngine
	dotnet add $@ package WebSocketSharp --version 1.0.3-rc1
	dotnet sln add $@

src/Infovis/Protobuf.cs: infovis.proto3
	protoc --csharp_out $(@D) $<
	mv src/Infovis/Infovis.cs $@


.PHONY: build clean restore run


.SUFFIXES:
