#!/usr/bin/env bash

set -x

./go-infovis --demo 0.0.0.0:42042 /infovis/v4/demo  \
             ../protobuf/examples/axes.pbb          \
             ../protobuf/examples/corner-points.pbb \
             ../protobuf/examples/rectangles.pbb    \
             ../protobuf/examples/helices.pbb       \
             ../protobuf/examples/bslm-??.pbb
