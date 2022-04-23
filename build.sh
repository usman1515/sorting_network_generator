#!/usr/bin/env bash

param=" "
max=10
nettype=("oddeven" "bitonic")
for n in "${nettype[@]}"; do
    for (( i=1; i<=$max; i++ )); do
        pow=$((2 ** $i))
        param="$param""generate --nettype=$n"\
#" --inputs=LOAD_SHIFT_REGISTER"\
#" --outputs=STORE_SHIFT_REGISTER"\
" --cs=BITCS_SYNC"\
" --template=Network.vhd"\
" --N=$pow"\
" --W=8"\
" --num_outputs=$pow"\
" --shape=max"
        if (( i != $max )); then
            param=$param" - "
        fi
    done
done

shape=("max" "min" "median")
for n in "${nettype[@]}"; do
    for s in "${shape[@]}"; do

    param="$param""generate --nettype=$n"\
#" --inputs=LOAD_SHIFT_REGISTER"\
#" --outputs=STORE_SHIFT_REGISTER"\
" --cs=BITCS_SYNC"\
" --template=Network.vhd"\
" --N=10"\
" --W=8"\
" --num_outputs=3"\
" --shape=$s"\
" - "
    done
done

#printf "$param"
python netgen.py $param write_log report
