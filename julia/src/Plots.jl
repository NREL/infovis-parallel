
import Colors: Colorant, @colorant_str
import DataFrames: DataFrame
import InfoVis.Primitives: Axis, Label, Points, Polylines, request
import InfoVis.Transport: Client
import StaticArrays: SVector


function axes(
; axisid    = 10000000                       :: Signed
, axiscolor = colorant"#035096a0"            :: Colorant
, labels    = ["x axis", "y axis", "z axis"] :: Vector{String}
, frame     = 1                              :: Signed
)
  request([
    Axis(axisid + 1, SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0), size = 0.02, color = axiscolor, text = "x axis", frame = frame)                             ,
    Axis(axisid + 2, SVector(0.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), size = 0.02, color = axiscolor, text = "y axis", frame = frame)                             ,
    Axis(axisid + 3, SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 1.0), size = 0.02, color = axiscolor, text = "z axis", frame = frame)                             ,
    Label(axisid + 4, labels[1], SVector( 0.1 , -0.1,  0.0 ), SVector( 1.0 , -0.1,  0.0 ), SVector(0.1, 1.0, 0.0), size = 0.10, color = axiscolor, frame = frame),
    Label(axisid + 5, labels[2], SVector(-0.07,  0.1, -0.07), SVector(-0.07,  1.0, -0.07), SVector(1.0, 0.1, 1.0), size = 0.10, color = axiscolor, frame = frame),
    Label(axisid + 6, labels[3], SVector( 0.0 , -0.1,  0.1 ), SVector( 0.0 , -0.1,  1.0 ), SVector(0.0, 1.0, 0.1), size = 0.10, color = axiscolor, frame = frame),
  ])
end

export axes


function scatterplot(
  df                          :: DataFrame
, i                           :: Symbol
, x                           :: Symbol
, y                           :: Symbol
, z                           :: Symbol
; size  = 0.01                :: Union{Symbol,Float64}
, color = colorant"#7DF9FFFF" :: Union{Symbol,Colorant}
, glyph = 0                   :: Union{Symbol,Signed}
, frame = 1                   :: Signed
)
  request([
    Points(
      getproperty(row, i)
    , [[SVector(
        getproperty(row, x)
      , getproperty(row, y)
      , getproperty(row, z)
      )]]
    , size  = typeof(size ) == Symbol ? getproperty(row, size ) : size
    , color = typeof(color) == Symbol ? getproperty(row, color) : color
    , glyph = typeof(glyph) == Symbol ? getproperty(row, glyph) : glyph
    , frame = frame
    )
    for row in eachrow(df)
  ])
end

export scatterplot


function lineplot(
  df                          :: DataFrame
, i                           :: Symbol
, x                           :: Symbol
, y                           :: Symbol
, z                           :: Symbol
; size  = 0.01                :: Union{Symbol,Float64}
, color = colorant"#7DF9FFFF" :: Union{Symbol,Colorant}
, glyph = 0                   :: Union{Symbol,Signed}
, frame = 1                   :: Signed
)
  request([
    Polylines(
      getproperty(row, i)
    , [[
        SVector(
          getproperty(row, x)[j]
        , getproperty(row, y)[j]
        , getproperty(row, z)[j]
        )
        for j in 1:length(getproperty(row, x))
      ]]
    , size  = typeof(size ) == Symbol ? getproperty(row, size ) : size
    , color = typeof(color) == Symbol ? getproperty(row, color) : color
    , glyph = typeof(glyph) == Symbol ? getproperty(row, glyph) : glyph
    , frame = frame
    )
    for row in eachrow(df)
  ])
end

export lineplot
