##
# BitSerialCompareSwap
#
# @file
# @version 0.1

# Author: Stephan Proß
# Date: 05.03.2023
# Description: Makefile for implementing test sorter using vivado.
# 			   Based on Makefile used in CVA6

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))

# --------------------------------------------------------------------
# ------- CONSTRAINTS AND BOARD DEFINITIONS --------------------------
# --------------------------------------------------------------------

# Either provide name of the board via commandline or change the
# default value here.
BOARD ?= nexys4ddr

# Don't forget to add your hardware target if it's not in the
# list.
ifeq ($(BOARD), nexys4ddr)
	XILINX_PART              := xc7a100tcsg324-1
	XILINX_BOARD             := digilentinc.com:nexys4_ddr:part0:1.1
	CONSTRAINTS 		     := $(root-dir)/constr/nexys4ddr.xdc
	TOPFILE                  := Test_Sorter_Top.vhd
else ifeq ($(BOARD), vcu118)
	XILINX_PART              := xcvu9p-flga2104-2L-e
	XILINX_BOARD             := xilinx.com:vcu118:part0:2.4
	CONSTRAINTS 		     := $(root-dir)/constr/vcu118.xdc
	TOPFILE                  := Test_Sorter_Top_VCU118.vhd
else
$(error Unknown board - please specify a supported FPGA board)
endif

# --------------------------------------------------------------------
# ------- SOURCES ----------------------------------------------------
# --------------------------------------------------------------------
#
# Add your library files containing packages and or global definitions
# here.
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
			src/Debouncer/Debouncer.vhd						   \
			top/$(TOPFILE)

ifdef SORTER
	src += $(wildcard $(SORTER)/*.vhd)
else
$(error must set SORTER to the desired generated sorter folder)
endif

src := $(addprefix $(root-dir)/, $(src))


work-dir := $(SORTER)/work_dir

BIT_FILE := $(work-dir)/$(TOP).bit
bit := $(BIT_FILE)

# TOP-Module/Component for synthesis & implementation
TOP ?= TEST_SORTER_TOP

VIVADOENV := BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CONSTRAINTS=$(CONSTRAINTS) BIT_FILE=$(BIT_FILE)
VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source $(root-dir)/scripts/prologue.tcl

#==== Default target - running simulation without drawing waveforms ====#
all: $(bit)

fpga: $(src)
	mkdir -p $(work-dir)
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(src)}    > $(work-dir)/add_sources.tcl
	@echo read_vhdl        {$(lib)}    >> $(work-dir)/add_sources.tcl
	@echo set_property IS_GLOBAL_INCLUDE 0 [get_files $(lib)] >> $(work-dir)/add_sources.tcl
	@echo set_property TOP ${TOP} [current_fileset] >> $(work-dir)/add_sources.tcl
	@echo set_property file_type {VHDL 2008} [get_files  *] >> $(work-dir)/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
.PHONY: fpga

$(bit): fpga
	cd $(work-dir) && $(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source $(root-dir)/scripts/run.tcl
	cp $(work-dir)/BitCS.runs/impl_1/$(TOP)* ./$(work-dir)


program:
	$(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source $(root-dir)/scripts/program.tcl

clean:
	rm -rf $(work-dir)

.PHONY:
	clean


# end
