
import InfoVis.Buffers: Request, Response
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
    io = IOBuffer()
    writeproto(io, request)
    if !writeguarded(socket, take!(io))
      break
    end
  end
  nothing
end


function _handler(
  socket  :: WebSocket
, channel :: Channel{Response}
) :: Nothing
  while socket.state == CONNECTED
    message, success = readguarded(socket)
    if !success
      break
    end
    response = readproto(message, Response())
    put!(cannel, response)
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
  @async WebSockets.open(address) do socket
    @async _handler(socket, requests)
    @async _handler(socket, responses)
    put!(ready, Done())
    take!(control)
    close(socket, statusnumber = 1000, freereason = "done")
  take!(ready)
  end
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
