
require("./infovis.proto3_pb")


function connect(url, handler, closer) {
  const connection = new WebSocket(url)
  connection.binaryType = "arraybuffer"
  handlers = new Object()
  connection.onmessage =
    function(event) {
      const buffer = new Uint8Array(event.data);
      const request = proto.Infovis.Request.deserializeBinary(buffer)
      handler(connection, request)
    }
  connection.onclose = closer
  return connection
}


function disconnect(connection) {
  connection.close(1000, "normal termination");
}


module.exports = {
  connect    : connect
, disconnect : disconnect
}
