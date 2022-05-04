#!/usr/bin/env bash

param=" "
max=10
nettype=("oddeven" "bitonic")
for n in "${nettype[@]}"; do
    for (( i=2; i<=$max; i++ )); do
        pow=$((2 ** $i))
        param="$param""generate --network_type=$n --N=$pow - "\
"fill_template --template_name=Network.vhd --cs=BITCS_SYNC - "\
"write_template - "
        if (( i != $max )); then
            param=$param" - "
        fi
    done
done

shape=("max" "min" "median")
for n in "${nettype[@]}"; do
    for s in "${shape[@]}"; do
        param="$param""generate --network_type=$n --N=10 - "\
"shape --shape_type=$s --num_outputs=3 - "\
"fill_template --template_name=Network.vhd --cs=BITCS_SYNC - "\
"write_template - "
    done
done

#printf "$param"
python netgen.py $param - write_report
