#!/usr/bin/env nix-shell
#!nix-shell -i "gawk -f" -p gawk

BEGIN {

  print "upsert {"
  print "  fram: 1"
  print "  iden: 301"
  print "  type: 2"
  print "  mask: 15"
  print "  cnts: 101"
  print "  cnts: 101"
  for (i = 0; i <= 100; ++i)
    print "  posx: " (i / 100)
  for (i = 0; i <= 100; ++i)
    print "  posx: " (i / 100)
  for (i = 0; i <= 100; ++i)
    print "  posy: " (0.5 + 0.4 * cos(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posy: " (0.5 - 0.4 * sin(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posz: " (0.5 + 0.4 * sin(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posz: " (0.5 + 0.4 * cos(4 * 3.1415926 / 100 * i))
  print "  size: 0.05"
  print "  colr: 4278190335"
  print "  text: \"two helices\""
  print "}"

  print "upsert {"
  print "  fram: 1"
  print "  iden: 302"
  print "  type: 2"
  print "  mask: 15"
  print "  cnts: 101"
  print "  cnts: 101"
  for (i = 0; i <= 100; ++i)
    print "  posx: " (i / 100)
  for (i = 0; i <= 100; ++i)
    print "  posx: " (i / 100)
  for (i = 0; i <= 100; ++i)
    print "  posy: " (0.5 - 0.4 * cos(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posy: " (0.5 + 0.4 * sin(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posz: " (0.5 - 0.4 * sin(4 * 3.1415926 / 100 * i))
  for (i = 0; i <= 100; ++i)
    print "  posz: " (0.5 - 0.4 * cos(4 * 3.1415926 / 100 * i))
  print "  size: 0.05"
  print "  colr: 1088475391"
  print "  text: \"another two helices\""
  print "}"


}
