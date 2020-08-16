
import infovis.proto3_pb2 as pb

from enum       import IntEnum
from itertools  import chain
from matplotlib import colors


def append_request(x, y):

  if y.show != 0:
    x.show = y.show
  if y.message != "":
    x.message = y.message

  x.reset |= y.reset

  x.upsert.extend(y.upsert)
  x.delete.extend(y.delete)

  if y.HasField("viewloc"):
    x.viewloc = y.viewloc
  if y.HasField("toolloc"):
    x.toolloc = y.toolloc
  if y.HasField("offsetloc"):
    x.offsetloc = y.offsetloc

  return x


def concat_requests(requests):
  x = empty()
  for y in requests:
    append_request(x, y)
  return x


def ShowFrame(frame):
  request = pb.Request()
  request.show = frame
  return request


def ShowMessage(message = None):
  request = pb.Request()
  request.message = message if message is not None and message != "" else " "
  return request


def ResetDisplay():
  request = pb.Request()
  request.reset = True
  return request


def empty(upserts = [], deletes = []):
  request = pb.Request()
  request.upsert.extend(upserts)
  request.delete.extend(deletes)
  return request


class GeomTypes(IntEnum):
  POINTS     = 1
  POLYLINES  = 2
  RECTANGLES = 3
  LABEL      = 4
  AXIS       = 5


class GlyphTypes(IntEnum):
  CUBES   = 0
  SPHERES = 1


def Geometry(
  geomtype  ,
  identifier,
  coords    ,
  frame     ,
  size      ,
  color     ,
  text      ,
  glyph     ,
):
  geometry = pb.Geometry()
  geometry.fram = frame
  geometry.iden = identifier
  geometry.type = geomtype
  geometry.mask = 31 if geomtype <= GeomTypes.POLYLINES else 15
  geometry.cnts.extend([len(ps) for ps in coords])
  geometry.posx.extend(chain.from_iterable(map(lambda ps: map(lambda p: p[0], ps), coords)))
  geometry.posy.extend(chain.from_iterable(map(lambda ps: map(lambda p: p[1], ps), coords)))
  geometry.posz.extend(chain.from_iterable(map(lambda ps: map(lambda p: p[2], ps), coords)))
  geometry.size = size
  geometry.colr = int(colors.to_hex(color, keep_alpha = True)[1:], 16)
  geometry.text = text
  geometry.glyp = glyph
  return geometry


def Points(
  identifier                   ,
  coords                       ,
  frame      = 1               ,
  size       = 0.01            ,
  color      = "#7DF9FFFF"     ,
  text       = ""              ,
  glyph      = GlyphTypes.CUBES,
):
  return empty(
    upserts = [
      Geometry(
        GeomTypes.POINTS,
        identifier      ,
        coords          ,
        frame           ,
        size            ,
        color           ,
        text            ,
        glyph           ,
      )
    ]
  )


def Polylines(
  identifier                   ,
  coords                       ,
  frame      = 1               ,
  size       = 0.01            ,
  color      = "#7DF9FFFF"     ,
  text       = ""              ,
  glyph      = GlyphTypes.CUBES,
):
  return empty(
    upserts = [
      Geometry(
        GeomTypes.POLYLINES,
        identifier         ,
        coords             ,
        frame              ,
        size               ,
        color              ,
        text               ,
        glyph              ,
      )
    ]
  )


def Rectangles(
  identifier              ,
  coords                  ,
  frame      = 1          ,
  size       = 0.01       ,
  color      = "#7DF9FFFF",
  text       = ""         ,
):
  return empty(
    upserts = [
      Geometry(
        GeomTypes.RECTANGLES,
        identifier          ,
        coords              ,
        frame               ,
        size                ,
        color               ,
        text                ,
        GlyphTypes.CUBES    ,
      )
    ]
  )
  

def Label(
  identifier             ,
  text                   ,
  origin                 ,
  horizontal             ,
  vertical               ,
  frame      = 1         ,
  size       = 0.01      ,
  color      = "7DF9FFFF",
):
  return empty(
    upserts = [
      Geometry(
        GeomTypes.LABEL                 ,
        identifier                      ,
        [[origin, horizontal, vertical]],
        frame                           ,
        size                            ,
        color                           ,
        text                            ,
        GlyphTypes.CUBES                ,
      )
    ]
  )


def Axis(
  identifier              ,
  start                   ,
  finish                  ,
  frame      = 1          ,
  size       = 0.01       ,
  color      = "#7DF9FFFF",
  text       = ""         ,
):
  return empty(
    upserts = [
      Geometry(
        GeomTypes.AXIS   ,
        identifier       ,
        [[start, finish]],
        frame            ,
        size             ,
        color            ,
        text             ,
        GlyphTypes.CUBES ,
      )
    ]
  )


def SetView(
  position = [0, 0, 0]   ,
  rotation = [1, 0, 0, 0],
):
  request = pb.Request()
  request.viewloc.posx = position[0]
  request.viewloc.posy = position[1]
  request.viewloc.posz = position[2]
  request.viewloc.rotw = rotation[0]
  request.viewloc.rotx = rotation[1]
  request.viewloc.roty = rotation[2]
  request.viewloc.rotz = rotation[3]
  return request


def SetTool(
  position = [0, 0, 0]   ,
  rotation = [1, 0, 0, 0],
):
  request = pb.Request()
  request.toolloc.posx = position[0]
  request.toolloc.posy = position[1]
  request.toolloc.posz = position[2]
  request.toolloc.rotw = rotation[0]
  request.toolloc.rotx = rotation[1]
  request.toolloc.roty = rotation[2]
  request.toolloc.rotz = rotation[3]
  return request


def SetOffset(
  position = [0, 0, 0]   ,
  rotation = [1, 0, 0, 0],
):
  request = pb.Request()
  request.offsetloc.posx = position[0]
  request.offsetloc.posy = position[1]
  request.offsetloc.posz = position[2]
  request.offsetloc.rotw = rotation[0]
  request.offsetloc.rotx = rotation[1]
  request.offsetloc.roty = rotation[2]
  request.offsetloc.rotz = rotation[3]
  return request


def position(location):
  return [
    location.posx,
    location.posy,
    location.posz,
  ]


def rotation(location):
  return [
    location.rotw,
    location.rotx,
    location.roty,
    location.rotz,
  ]
