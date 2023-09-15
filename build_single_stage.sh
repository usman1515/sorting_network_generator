#!/usr/bin/env bash

log_p=14
nettype=("ODDEVEN")
## The busiest stage with the "longest" connections is the first merger
## stage in every oddeven network. Since each network is recursively
## generated, the index of that stage is one after the depth of a network
## of 2**(log_p - 1) inputs.
## hw(log_p) = depth(log_p -1 ) + 1 =  (log_p * (log_p - 1) / 2)  + 1
## Since the indices start at zero 1 is subtracted:
## hw(log_p) = log_p*(log_p-1)/2
for alg in "${nettype[@]}"; do
    for ((i = 2; i <= log_p; i++)); do
        p=$((2 ** i))
        hw=$(((i * (i - 1)) / 2))
        param="generate $alg $p stagewise 1 - ""\
includ
e_stages [$hw]  - ""\
replace_ff REGISTER_DSP --entity_ff=48 --limit=6840 - ""\
write - "
        #python netgen.py $param
        echo "python netgen.py $param"
        #make BOARD=vcu118 SORTER="build/ODDEVEN_${i}X${i}_STAGEWISE_FULL"
    done
done

for alg in "${nettype[@]}"; do
    for ((i = 2; i <= log_p; i++)); do
        p=$((2 ** i))
        hw=$(((i * (i - 1)) / 2))
        #make BOARD=vcu118 SORTER="build/${alg}_${p}X${p}_STAGEWISE_STAGE${hw}_FULL"
        echo "make BOARD=vcu118 SORTER=\"build/${alg}_${p}X${p}_STAGEWISE_STAGE${hw}_FULL\""
    done
done
