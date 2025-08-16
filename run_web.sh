#!/bin/bash

./build_web.sh
OUT_DIR="dist/web"
cd $OUT_DIR
python3 -m http.server
