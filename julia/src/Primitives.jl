
import InfoVis.Buffers: Geometry, Location, Request
import InfoVis.Transport: Client, send
import StaticArrays: SVector


function request(request :: Request)
  function sender(client :: Client)
    send(client, request)
    client
  end
  sender
end

export request
  

function showframe(frame :: Signed)
  request(
    Request(
      show    = convert(Int32, frame)
    , message = ""
    , reset   = false
    , upsert  = []
    , delete  = []
    )
  )
end

export showframe


function showmessage(message = "" :: String)
  request(
    Request(
      show    = 0
    , message = message != "" ? message : " "
    , reset   = false
    , upsert  = []
    , delete  = []
    )
  )
end

export showmessage


function resetdisplay()
  request(
    Request(
      show    = 0
    , message = ""
    , reset   = true
    , upsert  = []
    , delete  = []
    )
  )
end

export resetdisplay


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
, color      :: Unsigned
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
  , colr  = convert(UInt32, color)
  , text  = text
  , glyp  = convert(Int32, glyph)
  )
end


function points(
  identifier         :: Signed
, coords             :: Vector{Vector{SVector{3,Float64}}}
; frame = 1          :: Signed
, size  = 0.01       :: Float64
, color = 0x035096FF :: Unsigned
, text  = ""         :: String
, glyph = 0          :: Signed
)
  request(
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
  )
end

export points


function polylines(
  identifier         :: Signed
, coords             :: Vector{Vector{SVector{3,Float64}}}
; frame = Int32(1)   :: Signed
, size  = 0.01       :: Float64
, color = 0x035096FF :: Unsigned
, text  = ""         :: String
, glyph = Int32(0)   :: Signed
)
  request(
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
  )
end

export polylines


function rectangles(
  identifier         :: Signed
, coords             :: Vector{SVector{3,SVector{3,Float64}}}
; frame = Int32(1)   :: Signed
, size  = 0.01       :: Float64
, color = 0x035096FF :: Unsigned
, text  = ""         :: String
)
  request(
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
  )
end

export rectangles


function label(
  identifier         :: Signed
, text               :: String
, origin             :: SVector{3,Float64}
, horizontal         :: SVector{3,Float64}
, vertical           :: SVector{3,Float64}
; frame = Int32(1)   :: Signed
, size  = 0.01       :: Float64
, color = 0x035096FF :: Unsigned
)
  request(
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
  )
end

export label


function axis(
  identifier         :: Signed
, start              :: SVector{3,Float64}
, finish             :: SVector{3,Float64}
; frame = Int32(1)   :: Signed
, size  = 0.01       :: Float64
, color = 0x035096FF :: Unsigned
, text  = ""         :: String
)
  request(
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
  )
end

export axis


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
  request(
    Request(
      show    = 0
    , message = ""
    , reset   = false
    , upsert  = []
    , delete  = []
    , viewloc = Location(position, rotation)
    )
  )
end

export setview


function settool(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
)
  request(
    Request(
      show    = 0
    , message = ""
    , reset   = false
    , upsert  = []
    , delete  = []
    , toolloc = Location(position, rotation)
    )
  )
end

export settool


function setoffset(
  position = SVector(0., 0., 0.)     :: SVector{3,Float64}
, rotation = SVector(1., 0., 0., 0.) :: SVector{4,Float64}
)
  request(
    Request(
      show      = 0
    , message   = ""
    , reset     = false
    , upsert    = []
    , delete    = []
    , offsetloc = Location(position, rotation)
    )
  )
end

export setoffset


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
