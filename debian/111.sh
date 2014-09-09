#!/bin/sh

cd ioping-0.8/
make
make install
./bench.py --deps

