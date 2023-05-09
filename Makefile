##
# BitSerialCompareSwap
#
# @file
# @version 0.1

# Author: Stephan Proß
# Date: 05.03.2023
# Description: Makefile for implementing test sorter using vivado.
# 			   Based on Makefile used in CVA6 and Vivado-Scripted-Flow Project
# 			   by Norbertas Kremeris

# setting additional xilinx board parameters for the selected board

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))

BOARD ?= nexys4ddr

ifeq ($(BOARD), nexys4ddr)
	XILINX_PART              := xc7a100tcsg324-1
	XILINX_BOARD             := digilentinc.com:nexys4_ddr:part0:1.1
	CONSTRAINTS 		     := $(root-dir)/constr/nexys4ddr.xdc
else
$(error Unknown board - please specify a supported FPGA board)
endif

# export BOARD=$(BOARD)
# export XILINX_PART=$(XILINX_PART)
# export XILINX_BOARD=$(XILINX_BOARD)
# export CLK_PERIOD_NS=$(CLK_PERIOD_NS)


lib := \
			lib/CustomTypes.vhd

lib := $(addprefix $(root-dir)/, $(lib))

src := \
			src/MUX/MUX_2X2.vhd                                \
			src/CS/SWCS.vhd                                    \
			src/Signal_Distributor/Signal_Distributor.vhd      \
			src/Shift_Registers/Store_Shift_Register.vhd       \
			src/Shift_Registers/Load_Shift_Register.vhd        \
			src/Shift_Registers/Register_DSP.vhd               \
			src/DeSerializer/Serializer_SR.vhd                 \
			src/DeSerializer/Deserializer_SR.vhd               \
			src/LFSR/LFSR.vhd                                  \
			src/Timer/Cycle_Timer.vhd                          \
			src/CS/SerialCompare.vhd                           \
			src/Validator/VALIDATOR.vhd                        \
			src/Debouncer/Debouncer.vhd                        \
			top/Test_Sorter_Top.vhd
			# src/Shift_Registers/Store_Shift_Register_BRAM.vhd  \
			# src/Shift_Registers/Load_Shift_Register_BRAM.vhd   \

ifdef SORTER
	src += $(wildcard $(SORTER)/*.vhd)
else
$(error must set SORTER to the desired generated sorter folder)
endif

src := $(addprefix $(root-dir)/, $(src))

top ?= TEST_SORTER_TOP

work-dir := $(SORTER)/work_dir
BIT_FILE := $(work-dir)/$(top).bit

VIVADOENV := BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CONSTRAINTS=$(CONSTRAINTS) BIT_FILE=$(BIT_FILE)
VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source $(root-dir)/scripts/prologue.tcl


bit := $(work-dir)/test_sorter_top.bit
mcs := $(work-dir)/test_sorter_top.mcs


#==== Default target - running simulation without drawing waveforms ====#
all: $(bit)

fpga: $(src)
	mkdir -p $(work-dir)
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(src)}    > $(work-dir)/add_sources.tcl
	@echo read_vhdl        {$(lib)}    >> $(work-dir)/add_sources.tcl
	@echo set_property IS_GLOBAL_INCLUDE 0 [get_files $(lib)] >> $(work-dir)/add_sources.tcl
	@echo set_property top ${top} [current_fileset] >> $(work-dir)/add_sources.tcl
	@echo set_property file_type {VHDL 2008} [get_files  *] >> $(work-dir)/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
.PHONY: fpga

$(bit): fpga
	cd $(work-dir) && $(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source $(root-dir)/scripts/run.tcl
	cp $(work-dir)/BitCS.runs/impl_1/$(top)* ./$(work-dir)

program:
	$(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source $(root-dir)/scripts/program.tcl

clean:
	rm -rf $(work-dir)

.PHONY:
	clean


# end
