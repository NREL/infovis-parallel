
from infovis.primitives import Axis, Label, Points, Polylines
from infovis.transport  import Client


class PlotClient(Client):

  def __init(self, address):
    super().__init__(address)

  def axes(
    self                                      ,
    axisid    = 10000000                      ,
    axiscolor = "#035096a0"                   ,
    labels    = ["x axis", "y axis", "z axis"],
    frame     = 1                             ,
  ):
    return self.requests([
      Axis(axisid + 1, [0.0, 0.0, 0.0], [1.0, 0.0, 0.0], size = 0.02, color = axiscolor, text = labels[0], frame = frame)                     ,
      Axis(axisid + 2, [0.0, 0.0, 0.0], [0.0, 1.0, 0.0], size = 0.02, color = axiscolor, text = labels[1], frame = frame)                     ,
      Axis(axisid + 3, [0.0, 0.0, 0.0], [0.0, 0.0, 1.0], size = 0.02, color = axiscolor, text = labels[2], frame = frame)                     ,
      Label(axisid + 4, labels[0], [ 0.1 , -0.1,  0.0 ], [ 1.0 , -0.1,  0.0 ], [0.1, 1.0, 0.0], size = 0.10, color = axiscolor, frame = frame),
      Label(axisid + 5, labels[1], [-0.07,  0.1, -0.07], [-0.07,  1.0, -0.07], [1.0, 0.1, 1.0], size = 0.10, color = axiscolor, frame = frame),
      Label(axisid + 6, labels[2], [ 0.0 , -0.1,  0.1 ], [ 0.0 , -0.1,  1.0 ], [0.0, 1.0, 0.1], size = 0.10, color = axiscolor, frame = frame),
    ])
  
  def scatterplot(
    self               ,
    df                 ,
    i                  ,
    x                  ,
    y                  ,
    z                  ,
    size  = 0.01       ,
    color = "#7DF9FFFF",
    glyph = 0          ,
    frame = 1          ,
  ):
    return self.requests([
      Points(
        row[i]                                                 ,
        [[[row[x], row[y], row[z]]]]                           ,
        size  = row[size ] if isinstance(size , str) else size ,
        color = row[color] if isinstance(color, str) else color,
        glyph = row[glyph] if isinstance(glyph, str) else glyph,
        frame = frame                                          ,
      )
      for _, row in df.iterrows()
    ])
  
  def lineplot(
    self               ,
    df                 ,
    i                  ,
    x                  ,
    y                  ,
    z                  ,
    size  = 0.01       ,
    color = "#7DF9FFFF",
    glyph = 0          ,
    frame = 1          ,
  ):
    return self.requests([
      Polylines(
        row[i]                                                           ,
        [[[row[x][j], row[y][j], row[z][j]] for j in range(len(row[x]))]],
        size  = row[size ] if isinstance(size , str) else size           ,
        color = row[color] if isinstance(color, str) else color          ,
        glyph = row[glyph] if isinstance(glyph, str) else glyph          ,
        frame = frame                                                    ,
      )
      for _, row in df.iterrows()
    ])
