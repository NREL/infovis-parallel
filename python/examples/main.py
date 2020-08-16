
import certifi
import ssl

import infovis as iv
import numpy   as np
import pandas  as pd

from math       import cos, pi, sin
from matplotlib import colors
from time       import sleep


if True:
  ssl_ctx = None
elif True:
  ssl_ctx = ssl.create_default_context()
  ssl_ctx.load_verify_locations(certifi.where())
else:
  ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
  ssl_ctx.load_verify_locations("ca_bundle.crt")


z = iv.PlotClient("wss://substrate.functionally.dev:42041/infovis/v4/julia", ssl_ctx)

z_thread = iv.websocket_thread_start(z)


z.reset_display()

z.axis(20000001, [0.0, 0.0, 0.0], [1.0, 0.0, 0.0], size = 0.02, color = "#035096a0", text = "x axis") \
 .axis(20000002, [0.0, 0.0, 0.0], [0.0, 1.0, 0.0], size = 0.02, color = "#035096a0", text = "y axis") \
 .axis(20000003, [0.0, 0.0, 0.0], [0.0, 0.0, 1.0], size = 0.02, color = "#035096a0", text = "z axis") ;

z.label(20000004, "x axis", [ 0.1 , -0.1,  0.0 ], [ 1.0 , -0.1,  0.0 ], [0.1, 1.0, 0.0], size = 0.10, color = "#035096a0") \
 .label(20000005, "y axis", [-0.07,  0.1, -0.07], [-0.07,  1.0, -0.07], [1.0, 0.1, 1.0], size = 0.10, color = "#035096a0") \
 .label(20000006, "z axis", [ 0.0 , -0.1,  0.1 ], [ 0.0 , -0.1,  1.0 ], [0.0, 1.0, 0.1], size = 0.10, color = "#035096a0") ;

z.show_frame(1)

sleep(2)


z.points(20000201, [[[0.0, 0.0, 0.0]]], size = 0.05, color = "#a6cee3ff", text = "one"  , glyph = iv.GlyphTypes.SPHERES) \
 .points(20000202, [[[1.0, 0.0, 0.0]]], size = 0.10, color = "#1f78b4ff", text = "two"  , glyph = iv.GlyphTypes.CUBES  ) \
 .points(20000203, [[[0.0, 1.0, 0.0]]], size = 0.15, color = "#b2df8aff", text = "three", glyph = iv.GlyphTypes.SPHERES) \
 .points(20000204, [[[1.0, 1.0, 0.0]]], size = 0.20, color = "#33a02cff", text = "four" , glyph = iv.GlyphTypes.CUBES  ) \
 .points(20000205, [[[0.0, 0.0, 1.0]]], size = 0.25, color = "#fb9a99ff", text = "five" , glyph = iv.GlyphTypes.SPHERES) \
 .points(20000206, [[[1.0, 0.0, 1.0]]], size = 0.30, color = "#e31a1cff", text = "six"  , glyph = iv.GlyphTypes.CUBES  ) \
 .points(20000207, [[[0.0, 1.0, 1.0]]], size = 0.35, color = "#fdbf6fff", text = "seven", glyph = iv.GlyphTypes.SPHERES) \
 .points(20000208, [[[1.0, 1.0, 1.0]]], size = 0.40, color = "#ff7f00ff", text = "eight", glyph = iv.GlyphTypes.CUBES  ) ;

z.polylines(20000301, [[
  [
    alpha
  , 0.2 + sin(pi * alpha)
  , (cos(pi * alpha) + 1) / 2
  ]
  for alpha in np.arange(0, 1.05, 0.05)
]], size = 0.05, color = "#40e0d0ff", text = "helices", glyph = 1, frame = 2)

z.rectangles(20000401, [
  [
    [0.0, 0.1, 0.1]
  , [0.0, 0.9, 0.1]
  , [0.0, 0.1, 0.9]
  ]
, [
    [1.0, 0.1, 0.1]
  , [1.0, 0.9, 0.1]
  , [1.0, 0.1, 0.9]
  ]
], size = 0.01, color = "#008000a0", text = "face", frame = 2)
z.rectangles(20000402, [
  [
    [0.0, 0.1, 0.1]
  , [1.0, 0.1, 0.1]
  , [0.0, 0.1, 0.9]
  ]
], size = 0.01, color = "#008000a0", text = "base", frame = 2)

sleep(5)

z.show_frame(2)

sleep(2)

def random_points(n):
  return pd.DataFrame({
    "ID"    : list(range(1, n + 1))                                                                                                ,
    "X"     : np.random.uniform(size = n)                                                                                          ,
    "Y"     : np.random.uniform(size = n)                                                                                          ,
    "Z"     : np.random.uniform(size = n)                                                                                          ,
    "Size"  : np.random.uniform(0.01, 0.06, size = n)                                                                              ,
    "Color" : [colors.to_hex((np.random.uniform(), np.random.uniform(), np.random.uniform()), keep_alpha = True) for i in range(n)],
    "Glyph" : [iv.GlyphTypes.CUBES if np.random.uniform() < 0.5 else iv.GlyphTypes.SPHERES for i in range(n)]                      ,
  })

def random_lines(n):
  return pd.DataFrame({
    "ID" : list(range(1, n + 1))                          ,
    "X"  : [np.random.uniform(size = 2) for i in range(n)],
    "Y"  : [np.random.uniform(size = 2) for i in range(n)],
    "Z"  : [np.random.uniform(size = 2) for i in range(n)],
  })

z.axes(frame = 3)                                                                                                 \
 .scatterplot(random_points(50), "ID", "X", "Y", "Z", size = "Size", color = "Color", glyph = "Glyph", frame = 3) \
 .lineplot(random_lines(5), "ID", "X", "Y", "Z", frame = 3)                                                       \
 .show_frame(3)                                                                                                   ;

sleep(2)

z.set_view([-5., 3., 15.])    \
 .set_tool([0.5, 0.5, 0.5])   \
 .set_offset([0.5, 0.5, 0.5]) ;

sleep(5)

z.show_message("goodbye")

sleep(2)

z.show_message()  \
 .reset_display() \
 .stop()          ;

sleep(2)
