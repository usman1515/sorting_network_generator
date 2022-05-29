# Step 1: define output directory
set output_folder output

# Step 2: create in-memory project and define target part
create_project -in_memory -part xcvu9p-flga2104-2L-e


# Step 3: read design sources and IP files
read_vhdl -vhdl2008   lib/CustomTypes.vhd
read_vhdl -vhdl2008   src/MUX/MUX_2X2.vhd
read_vhdl -vhdl2008   src/CS/BitCS_Sync.vhd
read_vhdl -vhdl2008   src/Shift_Registers/Shift_Register.vhd
read_vhdl -vhdl2008   src/Shift_Registers/Register_DSP.vhd
read_vhdl -vhdl2008   src/Signal_Distributor/Signal_Distributor.vhd

read_vhdl -vhdl2008   src/Shift_Registers/Load_Shift_Register.vhd
read_vhdl -vhdl2008   src/Shift_Registers/Load_Shift_Register_BRAM.vhd
read_vhdl -vhdl2008   src/Shift_Registers/Store_Shift_Register.vhd
read_vhdl -vhdl2008   src/Shift_Registers/Store_Shift_Register_BRAM.vhd
read_vhdl -vhdl2008   src/DeSerializer/Serializer_BRAM.vhd
read_vhdl -vhdl2008   src/DeSerializer/Serializer_SR.vhd
read_vhdl -vhdl2008   src/DeSerializer/Deserializer_SR.vhd
read_vhdl -vhdl2008   src/DeSerializer/Deserializer_BRAM.vhd

read_vhdl -vhdl2008   src/Timer/Cycle_Timer.vhd
read_vhdl -vhdl2008   src/Timer/Delay_Timer.vhd

read_vhdl -vhdl2008   build/ODDEVEN_64_TO_64_MAX.vhd

read_vhdl -vhdl2008   src/Sorter/Sorter.vhd
read_vhdl -vhdl2008   src/Debouncer/Debouncer.vhd
read_vhdl -vhdl2008   src/Validator/Validator.vhd
read_vhdl -vhdl2008   src/LFSR/LFSR.vhd
read_vhdl -vhdl2008   src/MUX/RR_DMUX_NxW.vhd

read_vhdl -vhdl2008   src/Test_Sorter/Test_Sorter_X.vhd

read_vhdl -vhdl2008   top/Test_Sorter_Top_VCU118.vhd

# Step 4: read synthesis constraints
# read_xdc constr/zedboard_master.xdc
read_xdc  constr/vcu118_rev2.0_12082017.xdc

# Step 5: run synthesis, report utilization and timing estimates, write post-synthesis design checkpoint
synth_design -top Test_Sorter_Top
report_timing_summary -file $output_folder/synthesis/post_synth_timing_summary.rpt
report_power -file $output_folder/synthesis/post_synth_power.rpt
write_checkpoint -force $output_folder/synthesis/post_synthesis_design_checkpoint

# Step 6: read implementation constraints
# read_xdc ../constraints/implementation.xdc
 
# Step 7: run placer and logic optimzation, report utilization and timing estimates, write post-place design checkpoint
opt_design
place_design
phys_opt_design
report_timing_summary -file $output_folder/place/post_place_timing_summary.rpt
write_checkpoint -force $output_folder/place/post_place_design_checkpoint
 
# Step 8: run router, report final utilization and timing , run drc, write post-route design checkpoint
route_design
report_timing_summary -file $output_folder/route/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $output_folder/route/post_route_timing.rpt
report_clock_utilization -file $output_folder/route/clock_util.rpt
report_utilization -file $output_folder/route/post_route_util.rpt
report_power -file $output_folder/route/post_route_power.rpt
report_drc -file $output_folder/route/post_route_drc.rpt
write_checkpoint -force $output_folder/route/post_route_design_checkpoint

# Step 9: generate bitstream
# write_bitstream -force $output_folder/bitstream/Test_Sorter_Top.bit

# Step 10: program bitstream
# open_hw_manager
# connect_hw_server -allow_non_jtag
# open_hw_target
# current_hw_device [get_hw_devices xc7z020_1]
# refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
# set_property PROBES.FILE {} [get_hw_devices xc7z020_1]
# set_property FULL_PROBES.FILE {} [get_hw_devices xc7z020_1]
# set_property PROGRAM.FILE {../output/bitstream/fpga_audio_processor.bit} [get_hw_devices xc7z020_1]
# program_hw_devices [get_hw_devices xc7z020_1]
# refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]
# close_hw_target
