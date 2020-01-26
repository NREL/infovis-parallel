
import DataFrames: DataFrame
import InfoVis.Primitives: axis, label, points
import InfoVis.Transport: Client
import StaticArrays: SVector


function scatterplot(
  df                           :: DataFrame
, i                            :: Symbol
, x                            :: Symbol
, y                            :: Symbol
, z                            :: Symbol
, size                         :: Union{Symbol,Float64}
, color                        :: Union{Symbol,Unsigned}
, glyph                        :: Union{Symbol,Signed}
; frame     = 1                :: Signed
, axisid    = 10000000         :: Signed
, axiscolor = UInt32(55613088) :: Unsigned
)
  function f(client)
    client |> axis(axisid + 1, SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0), size = 0.02, color = axiscolor, text = "x axis", frame = frame) |>
              axis(axisid + 2, SVector(0.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), size = 0.02, color = axiscolor, text = "y axis", frame = frame) |>
              axis(axisid + 3, SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 1.0), size = 0.02, color = axiscolor, text = "z axis", frame = frame) ;
    client |> label(axisid + 4, "x axis", SVector( 0.1 , -0.1,  0.0 ), SVector( 1.0 , -0.1,  0.0 ), SVector(0.1, 1.0, 0.0), size = 0.10, color = axiscolor, frame = frame) |>
              label(axisid + 5, "y axis", SVector(-0.07,  0.1, -0.07), SVector(-0.07,  1.0, -0.07), SVector(1.0, 0.1, 1.0), size = 0.10, color = axiscolor, frame = frame) |>
              label(axisid + 6, "z axis", SVector( 0.0 , -0.1,  0.1 ), SVector( 0.0 , -0.1,  1.0 ), SVector(0.0, 1.0, 0.1), size = 0.10, color = axiscolor, frame = frame) ;
    for row in eachrow(df)
      client |> points(
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
    end
    client
  end
  return f
end

export scatterplot
