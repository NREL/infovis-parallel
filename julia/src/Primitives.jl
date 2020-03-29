
import Base: append!
import Colors: Colorant, RGBA, @colorant_str
import InfoVis.Buffers: Geometry, Location, Request
import InfoVis.Transport: Client, send
import StaticArrays: SVector


function _colorant2uint(c :: Colorant) :: UInt32
  c1 = convert(RGBA, c)
  quantize(x) = round(UInt32, 0xFF * x)
  r = quantize(c1.r    )
  g = quantize(c1.g    )
  b = quantize(c1.b    )
  a = quantize(c1.alpha)
  0x100 * (0x100 * (0x100 * r + g) + b) + a
end


function append!(x :: Request, y :: Request) :: Request

  if y.show    != 0 ; x.show    = y.show   ; end
  if y.message != ""; x.message = y.message; end

  x.reset |= y.reset

  x.upsert = vcat(x.upsert, y.upsert)
  x.delete = vcat(x.delete, y.delete)

  if isdefined(y, :viewloc  ); x.viewloc   = y.viewloc  ; end
  if isdefined(y, :toolloc  ); x.toolloc   = y.toolloc  ; end
  if isdefined(y, :offsetloc); x.offsetloc = y.offsetloc; end

  x

end


function concat(requests :: AbstractVector{Request}) :: Request
  x = empty()
  for y in requests
    append!(x, y)
  end
  x
end

export concat


function request(request :: Request)
  function sender(client :: Client)
    send(client, request)
    client
  end
  sender
end

function request(requests :: AbstractVector{Request})
  request(concat(requests))
end

export request
  

function showframe(frame :: Signed)
  request(Showframe(frame))
end

export showframe


function Showframe(frame :: Signed) :: Request
  Request(
    show    = convert(Int32, frame)
  , message = ""
  , reset   = false
  , upsert  = []
  , delete  = []
  )
end

export Showframe


function showmessage(message = "" :: String)
  request(Showmessage(message))
end

export showmessage


function Showmessage(message = "" :: String) :: Request
  Request(
    show    = 0
  , message = message != "" ? message : " "
  , reset   = false
  , upsert  = []
  , delete  = []
  )
end

export Showmessage


function resetdisplay()
  request(Resetdisplay())
end

export resetdisplay


function Resetdisplay() :: Request
  Request(
    show    = 0
  , message = ""
  , reset   = true
  , upsert  = []
  , delete  = []
  )
end

export Resetdisplay


function empty(
  ; upserts = Geometry[] :: Vector{Geometry}
  , deletes = Int64[]    :: Vector{Int64}
) :: Request
  Request(
    show    = 0
  , message = ""
  , reset   = false
  , upsert  = upserts
  , delete  = deletes
  )
end

export empty


@enum Geometries POINTS POLYLINES RECTANGLES LABEL AXIS

export Geometries


function Geometry(
  geometry   :: Geometries
, identifier :: Signed
, coords     :: Vector{Vector{SVector{3,Float64}}}
, frame      :: Signed
, size       :: Float64
, color      :: Colorant
, text       :: String
, glyph      :: Signed
) :: Geometry
  Geometry(
    fram  = convert(Int32, frame)
  , iden  = convert(Int64, identifier)
  , _type = Int32(geometry) + 1
  , mask  = geometry <= POLYLINES ? 31 : 15
  , cnts  = map(Int32 ∘ length, coords)
  , posx  = vcat(map(ps -> map(p -> p[1], ps), coords)...)
  , posy  = vcat(map(ps -> map(p -> p[2], ps), coords)...)
  , posz  = vcat(map(ps -> map(p -> p[3], ps), coords)...)
  , size  = size
  , colr  = _colorant2uint(color)
  , text  = text
  , glyp  = convert(Int32, glyph)
  )
end


function points(
  identifier                  :: Signed
, coords                      :: Vector{Vector{SVector{3,Float64}}}
; frame = 1                   :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
, glyph = 0                   :: Signed
)
  request(Points(
    identifier   ,
    coords       ,
    frame = frame,
    size  = size ,
    color = color,
    text  = text ,
    glyph = glyph,
  ))
end

export points


function Points(
  identifier                  :: Signed
, coords                      :: Vector{Vector{SVector{3,Float64}}}
; frame = 1                   :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
, glyph = 0                   :: Signed
) :: Request
  empty(
    upserts = Geometry[
      Geometry(
        POINTS
      , identifier
      , coords
      , frame
      , size
      , color
      , text
      , glyph
      )
    ]
  )
end

export Points


function polylines(
  identifier                  :: Signed
, coords                      :: Vector{Vector{SVector{3,Float64}}}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
, glyph = Int32(0)            :: Signed
)
  request(Polylines(
    identifier   ,
    coords       ,
    frame = frame,
    size  = size ,
    color = color,
    text  = text ,
    glyph = glyph,
  ))
end

export polylines


function Polylines(
  identifier                  :: Signed
, coords                      :: Vector{Vector{SVector{3,Float64}}}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
, glyph = Int32(0)            :: Signed
) :: Request
  empty(
    upserts = Geometry[
      Geometry(
        POLYLINES
      , identifier
      , coords
      , frame
      , size
      , color
      , text
      , glyph
      )
    ]
  )
end

export Polylines


function rectangles(
  identifier                  :: Signed
, coords                      :: Vector{SVector{3,SVector{3,Float64}}}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
)
  request(Rectangles(
    identifier   ,
    coords       ,
    frame = frame,
    size  = size , 
    color = color,
    text  = text ,
  ))
end

export rectangles


function Rectangles(
  identifier                  :: Signed
, coords                      :: Vector{SVector{3,SVector{3,Float64}}}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
) :: Request
  empty(
    upserts = Geometry[
      Geometry(
        RECTANGLES
      , identifier
      , map(ps -> convert(Vector{SVector{3,Float64}}, ps), coords)
      , frame
      , size
      , color
      , text
      , Int32(0)
      )
    ]
  )
end

export Rectangles


function label(
  identifier                  :: Signed
, text                        :: String
, origin                      :: SVector{3,Float64}
, horizontal                  :: SVector{3,Float64}
, vertical                    :: SVector{3,Float64}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
)
  request(Label(
    identifier   ,
    text         ,
    origin       ,
    horizontal   ,
    vertical     ,
    frame = frame,
    size  = size ,
    color = color,
  ))
end

export label


function Label(
  identifier                  :: Signed
, text                        :: String
, origin                      :: SVector{3,Float64}
, horizontal                  :: SVector{3,Float64}
, vertical                    :: SVector{3,Float64}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
) :: Request
  empty(
    upserts = Geometry[
      Geometry(
        LABEL
      , identifier
      , [[origin, horizontal, vertical]]
      , frame
      , size
      , color
      , text
      , Int32(0)
      )
    ]
  )
end

export Label


function axis(
  identifier                  :: Signed
, start                       :: SVector{3,Float64}
, finish                      :: SVector{3,Float64}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
)
  request(Axis(
    identifier   ,
    start        ,
    finish       ,
    frame = frame,
    size  = size ,
    color = color,
    text  = text ,
  ))
end

export axis


function Axis(
  identifier                  :: Signed
, start                       :: SVector{3,Float64}
, finish                      :: SVector{3,Float64}
; frame = Int32(1)            :: Signed
, size  = 0.01                :: Float64
, color = colorant"#7DF9FFFF" :: Colorant
, text  = ""                  :: String
) :: Request
  empty(
    upserts = Geometry[
      Geometry(
        AXIS
      , identifier
      , [[start, finish]]
      , frame
      , size
      , color
      , text
      , Int32(0)
      )
    ]
  )
end

export Axis


function Location(
  position  :: SVector{3,Float64}
, rotation  :: SVector{4,Float64}
)
  Location(
    posx = position[1]
  , posy = position[2]
  , posz = position[3]
  , rotw = rotation[1]
  , rotx = rotation[2]
  , roty = rotation[3]
  , rotz = rotation[4]
  )
end


function setview(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
)
  request(Setview(position, rotation))
end

export setview


function Setview(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
) :: Request
  Request(
    show    = 0
  , message = ""
  , reset   = false
  , upsert  = []
  , delete  = []
  , viewloc = Location(position, rotation)
  )
end

export Setview


function settool(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
)
  request(Settool(position, rotation))
end

export settool


function Settool(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
) :: Request
  Request(
    show    = 0
  , message = ""
  , reset   = false
  , upsert  = []
  , delete  = []
  , toolloc = Location(position, rotation)
  )
end

export Settool


function setoffset(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
)
  request(Setoffset(position, rotation))
end

export setoffset


function Setoffset(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
) :: Request
  Request(
    show      = 0
  , message   = ""
  , reset     = false
  , upsert    = []
  , delete    = []
  , offsetloc = Location(position, rotation)
  )
end

export Setoffset


function position(location :: Location) :: SVector{3,Float64}
  SVector(
    location.posx
  , location.posy
  , location.posz
  )
end

export position


function rotation(location :: Location) :: SVector{4,Float64}
  SVector(
    location.rotw
  , location.rotx
  , location.roty
  , location.rotz
  )
end

export rotation
