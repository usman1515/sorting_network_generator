#!/bin/bash

options="\"options\":{ \"ghdl_analysis\": [\"--workdir=work\", \"--ieee=standard\", \"--std=08\", \"-fexplicit\"] },"
readarray -d '' vhd < <(find . -name "*.vhd" -print0)
readarray -d '' xdc < <(find . -name "*.xdc" -print0)



filesstring="\"files\":[\n"


let last=${#vhd[@]}-1
for ((i = 0; i < ${#vhd[@]}; ++i)); do
    filesstring="${filesstring} { \"file\": \"${vhd[$i]}\", \"language\":\"vhdl\" }"
    if [ $i != $last ]; then
        filesstring="${filesstring},\n"
    else
        filesstring="${filesstring} \n "    
    fi
    
done

# let last=${#xdc[@]}-1
# for ((i = 0; i < ${#xdc[@]}; ++i)); do
#     filesstring="${filesstring} { \"file\": \"${vhd[$i]}\", \"language\":\"xdc\" }"
#     if [ $i != $last ]; then
#         filesstring="${filesstring},\n"
#     else
#         filesstring="${filesstring} \n "    
#     fi
#     
# done


filesstring="${filesstring} \n ]"
echo -e "{ \n ${options} \n ${filesstring} \n }" > "hdl-prj_n.json"
