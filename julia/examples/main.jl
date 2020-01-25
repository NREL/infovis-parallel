
using InfoVis
using InfoVis.Primitives

import InfoVis.Transport: connect, stop
import StaticArrays: SVector


z = connect("ws://127.0.0.1:42042/julia") ;

sleep(5)

z |> axis(101, SVector(0.0, 0.0, 0.0), SVector(1.0, 0.0, 0.0), size = 0.02, color = UInt32(55613088), text = "x axis") |>
     axis(102, SVector(0.0, 0.0, 0.0), SVector(0.0, 1.0, 0.0), size = 0.02, color = UInt32(55613088), text = "y axis") |>
     axis(103, SVector(0.0, 0.0, 0.0), SVector(0.0, 0.0, 1.0), size = 0.02, color = UInt32(55613088), text = "z axis") ;

z |> label(111, "x axis", SVector( 0.1 , -0.1,  0.0 ), SVector( 1.0 , -0.1,  0.0 ), SVector(0.1, 1.0, 0.0), size = 0.10, color = UInt32(55613088)) |>
     label(112, "y axis", SVector(-0.07,  0.1, -0.07), SVector(-0.07,  1.0, -0.07), SVector(1.0, 0.1, 1.0), size = 0.10, color = UInt32(55613088)) |>
     label(113, "z axis", SVector( 0.0 , -0.1,  0.1 ), SVector( 0.0 , -0.1,  1.0 ), SVector(0.0, 1.0, 0.1), size = 0.10, color = UInt32(55613088)) ;

sleep(2)

z |> points(201, [[SVector(0.0, 0.0, 0.0)]], size = 0.05, color = UInt32(2798576639), text = "one"  , glyph = Int32(1)) |>
     points(202, [[SVector(1.0, 0.0, 0.0)]], size = 0.10, color = UInt32( 528004351), text = "two"  , glyph = Int32(0)) |>
     points(203, [[SVector(0.0, 1.0, 0.0)]], size = 0.15, color = UInt32(3000994559), text = "three", glyph = Int32(1)) |>
     points(204, [[SVector(1.0, 1.0, 0.0)]], size = 0.20, color = UInt32( 866135295), text = "four" , glyph = Int32(0)) |>
     points(205, [[SVector(0.0, 0.0, 1.0)]], size = 0.25, color = UInt32(4221213183), text = "five" , glyph = Int32(1)) |>
     points(206, [[SVector(1.0, 0.0, 1.0)]], size = 0.30, color = UInt32(3810139391), text = "six"  , glyph = Int32(0)) |>
     points(207, [[SVector(0.0, 1.0, 1.0)]], size = 0.35, color = UInt32(4257181695), text = "seven", glyph = Int32(1)) |>
     points(208, [[SVector(1.0, 1.0, 1.0)]], size = 0.40, color = UInt32(4286513407), text = "eight", glyph = Int32(0)) ;

z |> polylines(301, [[
                      SVector(
                        alpha
                      , 0.2 + sin(pi * alpha)
                      , (cos(pi * alpha) + 1) / 2
                      )
                      for alpha in 0.0:0.05:1.0
                    ]], size = 0.05, color = UInt32(1088475391), text = "helices", glyph = Int32(1), frame = Int32(2)) ;

z |> rectangles(401, [
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
                     ], size = 0.01, color = UInt32(8388768), text = "face", frame = Int32(2)) |>
     rectangles(402, [
                       SVector(
                         SVector(0.0, 0.1, 0.1)
                       , SVector(1.0, 0.1, 0.1)
                       , SVector(0.0, 0.1, 0.9)
                       )
                     ], size = 0.01, color = UInt32(8388768), text = "base", frame = Int32(2)) ;

sleep(5)

z |> showframe(2) ;

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
