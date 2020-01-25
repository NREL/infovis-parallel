
import InfoVis.Buffers: Geometry, Request
import InfoVis.Transport: Client, send
import StaticArrays: SVector


function empty(
  ; upserts = Geometry[] :: Vector{Geometry}
  , deletes = Int64[] :: Vector{Int64}
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


function request(request :: Request)
  function sender(client :: Client)
    send(client, request)
    client
  end
  sender
end

export request
  

@enum Geometries POINTS POLYLINES RECTANGLES LABEL AXIS

export Geometries


function Geometry(
  geometry   :: Geometries
, identifier :: Int64
, coords     :: Vector{Vector{SVector{3,Float64}}}
, frame      :: Int32
, size       :: Float64
, color      :: UInt32
, text       :: String
, glyph      :: Int32
) :: Geometry
  Geometry(
    fram  = frame
  , iden  = identifier
  , _type = Int32(geometry) + 1
  , mask  = geometry <= POLYLINES ? 31 : 15
  , cnts  = map(Int32 ∘ length, coords)
  , posx  = vcat(map(ps -> map(p -> p[1], ps), coords)...)
  , posy  = vcat(map(ps -> map(p -> p[2], ps), coords)...)
  , posz  = vcat(map(ps -> map(p -> p[3], ps), coords)...)
  , size  = size
  , colr  = color
  , text  = text
  , glyp  = glyph
  )
end


function points(
  identifier         :: Int64
, coords             :: Vector{Vector{SVector{3,Float64}}}
; frame = Int32(1)   :: Int32
, size  = 0.01       :: Float64
, color = 0x035096FF :: UInt32
, text  = ""         :: String
, glyph = Int32(0)   :: Int32
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
  identifier         :: Int64
, coords             :: Vector{Vector{SVector{3,Float64}}}
; frame = Int32(1)   :: Int32
, size  = 0.01       :: Float64
, color = 0x035096FF :: UInt32
, text  = ""         :: String
, glyph = Int32(0)   :: Int32
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
  identifier         :: Int64
, coords             :: Vector{SVector{3,SVector{3,Float64}}}
; frame = Int32(1)   :: Int32
, size  = 0.01       :: Float64
, color = 0x035096FF :: UInt32
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
  identifier         :: Int64
, text               :: String
, origin             :: SVector{3,Float64}
, horizontal         :: SVector{3,Float64}
, vertical           :: SVector{3,Float64}
; frame = Int32(1)   :: Int32
, size  = 0.01       :: Float64
, color = 0x035096FF :: UInt32
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
  identifier         :: Int64
, start              :: SVector{3,Float64}
, finish             :: SVector{3,Float64}
; frame = Int32(1)   :: Int32
, size  = 0.01       :: Float64
, color = 0x035096FF :: UInt32
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
