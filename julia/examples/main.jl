
using InfoVis
using InfoVis.Primitives

import DataFrames: DataFrame
import InfoVis.Plots: scatterplot
import InfoVis.Transport: connect, responses, stop
import Random: rand
import StaticArrays: SVector


z = connect("ws://127.0.0.1:42042/julia") ;

function reporter(response)
  if isdefined(response, :offsetloc)
    location = response.offsetloc
    position = InfoVis.Primitives.position(location)
    rotation = InfoVis.Primitives.rotation(location)
    println(position, " ", rotation)
  end
end

@async responses(z, reporter)

sleep(5)

z |> axis(20000001, SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0), size = 0.02, color = UInt32(55613088), text = "x axis") |>
     axis(20000002, SVector(0.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), size = 0.02, color = UInt32(55613088), text = "y axis") |>
     axis(20000003, SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 1.0), size = 0.02, color = UInt32(55613088), text = "z axis") ;

z |> label(20000004, "x axis", SVector( 0.1 , -0.1,  0.0 ), SVector( 1.0 , -0.1,  0.0 ), SVector(0.1, 1.0, 0.0), size = 0.10, color = UInt32(55613088)) |>
     label(20000005, "y axis", SVector(-0.07,  0.1, -0.07), SVector(-0.07,  1.0, -0.07), SVector(1.0, 0.1, 1.0), size = 0.10, color = UInt32(55613088)) |>
     label(20000006, "z axis", SVector( 0.0 , -0.1,  0.1 ), SVector( 0.0 , -0.1,  1.0 ), SVector(0.0, 1.0, 0.1), size = 0.10, color = UInt32(55613088)) ;

sleep(2)

z |> points(20000201, [[SVector(0.0, 0.0, 0.0)]], size = 0.05, color = UInt32(2798576639), text = "one"  , glyph = 1) |>
     points(20000202, [[SVector(1.0, 0.0, 0.0)]], size = 0.10, color = UInt32( 528004351), text = "two"  , glyph = 0) |>
     points(20000203, [[SVector(0.0, 1.0, 0.0)]], size = 0.15, color = UInt32(3000994559), text = "three", glyph = 1) |>
     points(20000204, [[SVector(1.0, 1.0, 0.0)]], size = 0.20, color = UInt32( 866135295), text = "four" , glyph = 0) |>
     points(20000205, [[SVector(0.0, 0.0, 1.0)]], size = 0.25, color = UInt32(4221213183), text = "five" , glyph = 1) |>
     points(20000206, [[SVector(1.0, 0.0, 1.0)]], size = 0.30, color = UInt32(3810139391), text = "six"  , glyph = 0) |>
     points(20000207, [[SVector(0.0, 1.0, 1.0)]], size = 0.35, color = UInt32(4257181695), text = "seven", glyph = 1) |>
     points(20000208, [[SVector(1.0, 1.0, 1.0)]], size = 0.40, color = UInt32(4286513407), text = "eight", glyph = 0) ;

z |> polylines(20000301, [[
                      SVector(
                        alpha
                      , 0.2 + sin(pi * alpha)
                      , (cos(pi * alpha) + 1) / 2
                      )
                      for alpha in 0.0:0.05:1.0
                    ]], size = 0.05, color = UInt32(1088475391), text = "helices", glyph = 1, frame = 2) ;

z |> rectangles(20000401, [
                       SVector(
                         SVector(0.0, 0.1, 0.1)
                       , SVector(0.0, 0.9, 0.1)
                       , SVector(0.0, 0.1, 0.9)
                       )
                     , SVector(
                         SVector(1.0, 0.1, 0.1)
                       , SVector(1.0, 0.9, 0.1)
                       , SVector(1.0, 0.1, 0.9)
                       )
                     ], size = 0.01, color = UInt32(8388768), text = "face", frame = 2) |>
     rectangles(20000402, [
                       SVector(
                         SVector(0.0, 0.1, 0.1)
                       , SVector(1.0, 0.1, 0.1)
                       , SVector(0.0, 0.1, 0.9)
                       )
                     ], size = 0.01, color = UInt32(8388768), text = "base", frame = 2) ;

sleep(5)

z |> showframe(2) ;

sleep(2)

function randomdata(n :: Signed)
  df = DataFrame()
  df.ID    = 1:n
  df.X     = [rand() for i in 1:n]
  df.Y     = [rand() for i in 1:n]
  df.Z     = [rand() for i in 1:n]
  df.Size  = [0.01 + 0.05 * rand() for i in 1:n]
  df.Color = [floor(UInt32, rand() * 0xFFFFFF) * 0x100 + 0xFF for i in 1:n]
  df.Glyph = [rand() < 0.5 ? 0 : 1 for i in 1:n]
  df
end

z |> scatterplot(randomdata(50) , :ID, :X, :Y, :Z, :Size, :Color, :Glyph, frame = 3) ;

z |> showframe(3) ;

sleep(2)

z |> setview(SVector(-5., 3., 15.))    |>
     settool(SVector(0.5, 0.5, 0.5))   |>
     setoffset(SVector(0.5, 0.5, 0.5)) ;

sleep(5)

z |> showmessage("goodbye") ;

sleep(2)

z |> showmessage()  |>
     resetdisplay() |>
     stop ;

sleep(2)
