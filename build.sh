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


python netgen.py generate oddeven \
    -input LOAD_SHIFT_REGISTER \
    -output STORE_SHIFT_REGISTER \
    -cs BITCS_SYNC \
    -template SortNetSync.vhd \
    -N 10 \
    -shape MAX \
    -num_outputs 3

python netgen.py generate oddeven \
    -input LOAD_SHIFT_REGISTER \
    -output STORE_SHIFT_REGISTER \
    -cs BITCS_SYNC \
    -template SortNetSync.vhd \
    -N 10 \
    -shape MIN \
    -num_outputs 3

python netgen.py generate oddeven \
    -input LOAD_SHIFT_REGISTER \
    -output STORE_SHIFT_REGISTER \
    -cs BITCS_SYNC \
    -template SortNetSync.vhd \
    -N 10 \
    -shape MEDIAN \
    -num_outputs 3
