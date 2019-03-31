BEGIN {
  OFS = "\t"
  print "Wall Area", "Roof Area", "Heating Load"
}

END {
  for (i = 0; i <= 1; i += 0.1) {
    print 1 + 9 * 0, 100 + 100 * 0, 10 + 10 * i
    print 1 + 9 * 0, 100 + 100 * i, 10 + 10 * 1
    print 1 + 9 * i, 100 + 100 * 1, 10 + 10 * 1
    print 1 + 9 * i, 100 + 100 * i, 10 + 10 * i
  }
}
