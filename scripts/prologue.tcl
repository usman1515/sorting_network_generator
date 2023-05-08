# Tcl script from CVA6 Project

set project BitCS

create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]

set_param general.maxThreads 8

set_msg_config -id {[Synth 8-5858]} -new_severity "info"

set_msg_config -id {[Synth 8-4480]} -limit 1000
