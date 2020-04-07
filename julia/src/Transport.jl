
import InfoVis.Buffers: Request, Response
import MbedTLS: SSLConfig
import ProtoBuf: readproto, writeproto
import WebSockets: WebSockets, WebSocket, close, open, readguarded, writeguarded, CONNECTED


struct Done end


Client = NamedTuple{(:control, :requests, :responses), Tuple{Channel{Done}, Channel{Request}, Channel{Response}}}

export Client


function _handler(
  socket  :: WebSocket
, channel :: Channel{Request}
) :: Nothing
  for request in channel
    try
      io = IOBuffer()
      writeproto(io, request)
      if !writeguarded(socket, take!(io))
        break
      end
    catch e
      @error e
    end
  end
  nothing
end


function _handler(
  socket  :: WebSocket
, channel :: Channel{Response}
) :: Nothing
  while socket.state == CONNECTED
    try
      message, success = readguarded(socket)
      if !success
        break
      end
      io = IOBuffer(message)
      response = readproto(io, Response())
      put!(channel, response)
    catch e
      @error e
    end
  end
  nothing
end


function connect(
  address         :: String
; capacity = 1000 :: Int64
) :: Client
  ready     = Channel{Done}(1)
  control   = Channel{Done}(1)
  requests  = Channel{Request}(1)
  responses = Channel{Response}(capacity)
  @async WebSockets.open(address; sslconfig=SSLConfig(false)) do socket
    @async _handler(socket, requests)
    @async _handler(socket, responses)
    put!(ready, Done())
    take!(control)
    close(requests)
    close(responses)
    close(socket, statusnumber = 1000, freereason = "done")
  end
  take!(ready)
  (
    control   = control
  , requests  = requests
  , responses = responses
  )
end

export connect


function send(client :: Client, request :: Request) :: Nothing
  put!(client.requests, request)
  nothing
end

export send


function receive(client :: Client) :: Response
  take!(client.responses)
end

export receive


function stop(client :: Client) :: Nothing
  put!(client.control, Done())
  nothing
end

export stop


function responses(client :: Client, handler = x -> nothing) :: Nothing
  for response in client.responses
    handler(response)
  end
end

export responses
