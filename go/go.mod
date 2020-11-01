module bitbucket.org/bwbush/infovis-parallel/go

go 1.12

replace (
	bitbucket.org/bwbush/infovis-parallel/go/infovis => ./infovis
	bitbucket.org/bwbush/infovis-parallel/go/infovis/export => ./infovis/export
	bitbucket.org/bwbush/infovis-parallel/go/infovis/model => ./infovis/model
	bitbucket.org/bwbush/infovis-parallel/go/infovis/switchboard => ./infovis/switchboard
)

require (
	bitbucket.org/bwbush/infovis-parallel/go/infovis v0.0.0-00010101000000-000000000000
	bitbucket.org/bwbush/infovis-parallel/go/infovis/export v0.0.0-00010101000000-000000000000
	bitbucket.org/bwbush/infovis-parallel/go/infovis/model v0.0.0-00010101000000-000000000000 // indirect
	bitbucket.org/bwbush/infovis-parallel/go/infovis/switchboard v0.0.0-00010101000000-000000000000
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	github.com/gorilla/websocket v1.4.2 // indirect
	github.com/segmentio/kafka-go v0.4.8 // indirect
	github.com/simulatedsimian/joystick v1.0.1 // indirect
)
