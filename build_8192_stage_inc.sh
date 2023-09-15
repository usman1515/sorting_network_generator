#!/usr/bin/env bash

nettype=("ODDEVEN")
limit=256
p=$((2 ** 13))
for alg in "${nettype[@]}"; do
    for ((i = 2; i <= limit; i++)); do
        param="generate $alg $p stagewise 1 - ""\
include_stages_range 0 $i - ""\
replace_ff REGISTER_DSP --entity_ff=48 --limit=6840 - ""\
write - "
        echo "python netgen.py $param"
        python netgen.py $param
    done
done

for alg in "${nettype[@]}"; do
    for ((i = 2; i <= limit; i++)); do
        echo "make BOARD=vcu118 SORTER=\"build/${alg}_${p}X${p}_STAGEWISE_S${i}_FULL\""
        make BOARD=vcu118 SORTER="build/${alg}_${p}X${p}_STAGEWISE_STAGE${i}_FULL"
    done
done
