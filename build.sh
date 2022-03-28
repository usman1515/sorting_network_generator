#!/usr/bin/env bash

for i in {2..10}; do
    pow=$((2 ** $i))

    python netgen.py generate evenodd \
        -input LoadShiftRegister \
        -output StoreShiftRegister \
        -cs BitCS \
        -template SortNet.vhd \
        -N $pow

done
