#!/usr/bin/env bash

for i in {1..10}; do
    pow=$((2 ** $i))

    python netgen.py generate oddeven \
        -input LOAD_SHIFT_REGISTER \
        -output STORE_SHIFT_REGISTER \
        -cs BITCS_SYNC \
        -template SortNetSync.vhd \
        -N $pow

done
