#!/usr/bin/env nix-shell
#!nix-shell -i "gawk -f" -p gawk

BEGIN {
  OFS = " "
  n = 16
  o = 1
  r = 0.75
  h = 0.2
  pi = 4 * atan2(1, 1)
  print "v", 0, o + h, 0
  for (i = 0; i < n; ++i)
    print "v", r * cos(2 * pi / n * i), o, r * sin(2 * pi / n * i)
  for (i = 0; i < n; ++i)
    print "f", i + 2, 1, (i + 1) % n + 2
  line = "f"
  for (i = 0; i < n; ++i)
    line = line OFS (i + 2)
  print line

}
