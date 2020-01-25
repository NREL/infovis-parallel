
using InfoVis

import InfoVis.Buffers: Geometry, Request
import InfoVis.Transport: connect, send, stop


req = Request(
  show    = 1
, message = ""
, reset   = true
, delete  = Vector{Int64}()
, upsert  = [
              Geometry(
                fram  = 1
              , iden  = 101
              , _type = 5
              , mask  = 15
              , cnts  = [2]
              , posx  = [0.0, 1.0]
              , posy  = [0.0, 0.0]
              , posz  = [0.0, 0.0]
              , size  = 0.02
              , colr  = 0x035096a0
              , text  = "x axis"
              , glyp  = 0
              )
            , Geometry(
                fram  = 1
              , iden  = 102
              , _type = 5
              , mask  = 15
              , cnts  = [2]
              , posx  = [0.0, 0.0]
              , posy  = [0.0, 1.0]
              , posz  = [0.0, 0.0]
              , size  = 0.02
              , colr  = 0x035096a0
              , text  = "y axis"
              , glyp  = 0
              )
            , Geometry(
                fram  = 1
              , iden  = 103
              , _type = 5
              , mask  = 15
              , cnts  = [2]
              , posx  = [0.0, 0.0]
              , posy  = [0.0, 0.0]
              , posz  = [0.0, 1.0]
              , size  = 0.02
              , colr  = 0x035096a0
              , text  = "z axis"
              , glyp  = 0
              )
            , Geometry(
                fram  = 1
              , iden  = 111
              , _type = 4
              , mask  = 15
              , cnts  = [3]
              , posx  = [ 0.1,  1.0, 0.1]
              , posy  = [-0.1, -0.1, 1.0]
              , posz  = [ 0.0,  0.0, 0.0]
              , size  = 0.1
              , colr  = 0x035096a0
              , text  = "x axis"
              , glyp  = 0
              )
            , Geometry(
                fram  = 1
              , iden  = 112
              , _type = 4
              , mask  = 15
              , cnts  = [3]
              , posx  = [-0.07, -0.07, 1.0]
              , posy  = [ 0.1 ,  1.0 , 0.1]
              , posz  = [-0.07, -0.07, 1.0]
              , size  = 0.1
              , colr  = 0x035096a0
              , text  = "y axis"
              , glyp  = 0
              )
            , Geometry(
                fram  = 1
              , iden  = 113
              , _type = 4
              , mask  = 15
              , cnts  = [3]
              , posx  = [ 0.0,  0.0, 0.0]
              , posy  = [-0.1, -0.1, 1.0]
              , posz  = [ 0.1,  1.0, 0.1]
              , size  = 0.1
              , colr  = 0x035096a0
              , text  = "z axis"
              , glyp  = 0
              )
            ]
)


rws = connect("ws://127.0.0.1:42042/julia")

sleep(2)

send(rws, req)

sleep(2)

stop(rws)

sleep(2)
