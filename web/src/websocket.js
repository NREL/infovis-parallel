require("./infovis.proto3_pb")


function connect(url, handler, closer) {
  var connection = new WebSocket(url)
  connection.binaryType = "arraybuffer"
  handlers = new Object()
  connection.onmessage =
    function(event) {
      var buffer = new Uint8Array(event.data);
      var request = proto.Infovis.Request.deserializeBinary(buffer)
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
