
import asyncio
import ssl
import threading
import websockets

from infovis.primitives import *
from infovis.proto3_pb2 import Request, Response
from queue              import Queue


def websocket_thread_start(client, loop = asyncio.get_event_loop()):
  def run():
    asyncio.set_event_loop(loop)
    loop.run_until_complete(client.connect())
  t = threading.Thread(target = run)
  t.start()
  return t


class Client:

  def __init__(self, address, ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)):
    self.address = address
    self.ssl_context = ssl_context
    self.pending_requests  = Queue()
    self.pending_responses = Queue()
    if ssl_context is None:
      self.ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
      self.ssl_context.check_hostname = False
      self.ssl_context.verify_mode = ssl.CERT_NONE
    else:
      self.ssl_context = ssl_context

  async def connect(self):
    async with websockets.connect(self.address, ssl = self.ssl_context) as socket:
      async def produce():
        while True:
          message = None
          while True:
            await asyncio.sleep(0)
            try:
              message = self.pending_requests.get(timeout = 0.005)
              break
            except:
              None
          if message == None:
            break
          await socket.send(message)
      async def consume():
        while True:
          message = await socket.recv()
          self.pending_responses.put(message)
      done, pending = await asyncio.wait(
        [
          asyncio.create_task(produce()),
          asyncio.create_task(consume()),
        ],
        return_when = asyncio.FIRST_COMPLETED
      )
      for task in pending:
        task.cancel()
  
  def stop(self):
    self.pending_requests.put(None)

  def response(self, timeout = None):
    response = None
    try:
      message = self.pending_responses.get(timeout = 0 if timeout is None else timeout)
    except:
      None
    response = Response()
    response.ParseFromString(message)
    return response

  def request(self, request):
    message = request.SerializeToString()
    self.pending_requests.put(message)
    return self

  def requests(self, requests):
    return self.request(concat_requests(requests))

  def show_frame(self, frame):
    return self.request(ShowFrame(frame))

  def show_message(self, message = ""):
    return self.request(ShowMessage(message))

  def reset_display(self):
    return self.request(ResetDisplay())

  def points(
    self                         ,
    identifier                   ,
    coords                       ,
    frame      = 1               ,
    size       = 0.01            ,
    color      = "#7DF9FFFF"     ,
    text       = ""              ,
    glyph      = GlyphTypes.CUBES,
  ):
    return self.request(Points(
      identifier,
      coords    ,
      frame     ,
      size      ,
      color     ,
      text      ,
      glyph     ,
    ))

  def polylines(
    self                         ,
    identifier                   ,
    coords                       ,
    frame      = 1               ,
    size       = 0.01            ,
    color      = "#7DF9FFFF"     ,
    text       = ""              ,
    glyph      = GlyphTypes.CUBES,
  ):
    return self.request(Polylines(
      identifier,
      coords    ,
      frame     ,
      size      ,
      color     ,
      text      ,
      glyph     ,
    ))

  def rectangles(
    self                    ,
    identifier              ,
    coords                  ,
    frame      = 1          ,
    size       = 0.01       ,
    color      = "#7DF9FFFF",
    text       = ""         ,
  ):
    return self.request(Rectangles(
      identifier,
      coords    ,
      frame     ,
      size      ,
      color     ,
      text      ,
    ))

  def label(
    self                   ,
    identifier             ,
    text                   ,
    origin                 ,
    horizontal             ,
    vertical               ,
    frame      = 1         ,
    size       = 0.01      ,
    color      = "7DF9FFFF",
  ):
    return self.request(Label(
      identifier,
      text      ,
      origin    ,
      horizontal,
      vertical  ,
      frame     ,
      size      ,
      color     ,
    ))

  def axis(
    self                    ,
    identifier              ,
    start                   ,
    finish                  ,
    frame      = 1          ,
    size       = 0.01       ,
    color      = "#7DF9FFFF",
    text       = ""         ,
  ):
    return self.request(Axis(
      identifier,
      start     ,
      finish    ,
      frame     ,
      size      ,
      color     ,
      text      ,
    ))

  def set_view(
    self                   ,
    position = [0, 0, 0]   ,
    rotation = [1, 0, 0, 0],
  ):
    return self.request(SetView(position, rotation))

  def set_tool(
    self                   ,
    position = [0, 0, 0]   ,
    rotation = [1, 0, 0, 0],
  ):
    return self.request(SetTool(position, rotation))

  def set_offset(
    self                   ,
    position = [0, 0, 0]   ,
    rotation = [1, 0, 0, 0],
  ):
    return self.request(SetOffset(position, rotation))
