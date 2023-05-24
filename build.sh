#!/usr/bin/env bash

max=10
nettype=("oddeven" "bitonic")
for n in "${nettype[@]}"; do
    for (( i=2; i<=$max; i++ )); do
        pow=$((2 ** $i))
        param="generate $n $pow - "\
"distribute_signal START 50  - "\
"replace_ff REGISTER_DSP --entity_ff=48 --limit=6840 - "\
"write - "
python netgen.py $param
    done
done

# shape=("max" "min" "median")
# for n in "${nettype[@]}"; do
#     for s in "${shape[@]}"; do
#         param="$param""generate --network_type=$n --N=10 - "\
# "shape --shape_type=$s --num_outputs=3 - "\
# "distribute_signal START 50 - "\
# "replace_ff REGISTER_DSP --ff_per_entity=48  --ff_per_entity_layer=[4] --max_entities=6840 - "\
# "fill_template --template_name=Network.vhd --cs=BITCS_SYNC - "\
# "write_template - "
#     done
# done

printf "$param"
