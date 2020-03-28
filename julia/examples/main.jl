
using InfoVis
using InfoVis.Primitives

import Colors: RGB, @colorant_str
import DataFrames: DataFrame
import InfoVis.Plots: axes, lineplot, scatterplot
import InfoVis.Transport: connect, responses, stop
import Random: rand
import StaticArrays: SVector


z = connect("ws://104.198.152.159:42042/infovis/v4/julia") ;

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

z |> axis(20000001, SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0), size = 0.02, color = colorant"#035096a0", text = "x axis") |>
     axis(20000002, SVector(0.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), size = 0.02, color = colorant"#035096a0", text = "y axis") |>
     axis(20000003, SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 1.0), size = 0.02, color = colorant"#035096a0", text = "z axis") ;

z |> label(20000004, "x axis", SVector( 0.1 , -0.1,  0.0 ), SVector( 1.0 , -0.1,  0.0 ), SVector(0.1, 1.0, 0.0), size = 0.10, color = colorant"#035096a0") |>
     label(20000005, "y axis", SVector(-0.07,  0.1, -0.07), SVector(-0.07,  1.0, -0.07), SVector(1.0, 0.1, 1.0), size = 0.10, color = colorant"#035096a0") |>
     label(20000006, "z axis", SVector( 0.0 , -0.1,  0.1 ), SVector( 0.0 , -0.1,  1.0 ), SVector(0.0, 1.0, 0.1), size = 0.10, color = colorant"#035096a0") ;

z |> showframe(1) ;

sleep(2)

z |> points(20000201, [[SVector(0.0, 0.0, 0.0)]], size = 0.05, color = colorant"#a6cee3ff", text = "one"  , glyph = 1) |>
     points(20000202, [[SVector(1.0, 0.0, 0.0)]], size = 0.10, color = colorant"#1f78b4ff", text = "two"  , glyph = 0) |>
     points(20000203, [[SVector(0.0, 1.0, 0.0)]], size = 0.15, color = colorant"#b2df8aff", text = "three", glyph = 1) |>
     points(20000204, [[SVector(1.0, 1.0, 0.0)]], size = 0.20, color = colorant"#33a02cff", text = "four" , glyph = 0) |>
     points(20000205, [[SVector(0.0, 0.0, 1.0)]], size = 0.25, color = colorant"#fb9a99ff", text = "five" , glyph = 1) |>
     points(20000206, [[SVector(1.0, 0.0, 1.0)]], size = 0.30, color = colorant"#e31a1cff", text = "six"  , glyph = 0) |>
     points(20000207, [[SVector(0.0, 1.0, 1.0)]], size = 0.35, color = colorant"#fdbf6fff", text = "seven", glyph = 1) |>
     points(20000208, [[SVector(1.0, 1.0, 1.0)]], size = 0.40, color = colorant"#ff7f00ff", text = "eight", glyph = 0) ;

z |> polylines(20000301, [[
                      SVector(
                        alpha
                      , 0.2 + sin(pi * alpha)
                      , (cos(pi * alpha) + 1) / 2
                      )
                      for alpha in 0.0:0.05:1.0
                    ]], size = 0.05, color = colorant"#40e0d0ff", text = "helices", glyph = 1, frame = 2) ;

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
                     ], size = 0.01, color = colorant"#008000a0", text = "face", frame = 2) |>
     rectangles(20000402, [
                       SVector(
                         SVector(0.0, 0.1, 0.1)
                       , SVector(1.0, 0.1, 0.1)
                       , SVector(0.0, 0.1, 0.9)
                       )
                     ], size = 0.01, color = colorant"#008000a0", text = "base", frame = 2) ;

sleep(5)

z |> showframe(2) ;

sleep(2)

function randompoints(n :: Signed)
  df = DataFrame()
  df.ID    = 1:n
  df.X     = [rand() for i in 1:n]
  df.Y     = [rand() for i in 1:n]
  df.Z     = [rand() for i in 1:n]
  df.Size  = [0.01 + 0.05 * rand() for i in 1:n]
  df.Color = [RGB(rand(), rand(), rand()) for i in 1:n]
  df.Glyph = [rand() < 0.5 ? 0 : 1 for i in 1:n]
  df
end

function randomlines(n :: Signed)
  df = DataFrame()
  df.ID    = 1:n
  df.X     = [[rand(), rand()] for i in 1:n]
  df.Y     = [[rand(), rand()] for i in 1:n]
  df.Z     = [[rand(), rand()] for i in 1:n]
  df
end

z |> axes(frame = 3) |>
     scatterplot(randompoints(50), :ID, :X, :Y, :Z, size  = :Size, color = :Color, glyph = :Glyph, frame = 3) |>
     lineplot(randomlines(5), :ID, :X, :Y, :Z, frame = 3) |>
     showframe(3) ;

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
