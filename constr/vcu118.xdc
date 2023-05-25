#
# Copyright (c) 2020 Wuklab, UC San Diego. All rights reserved.
#

# XDC constraints for the Xilinx VCU118 board
# part: xcvu9p-flga2104-2L-e

# General configuration
set_property CFGBVS GND                                [current_design]
set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8           [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]

# System clocks
# 300 MHz
#set_property -dict {LOC G31  IOSTANDARD DIFF_SSTL12} [get_ports clk_300mhz_p]
#set_property -dict {LOC F31  IOSTANDARD DIFF_SSTL12} [get_ports clk_300mhz_n]
#create_clock -period 3.333 -name clk_300mhz [get_ports clk_300mhz_p]

# 250 MHz
#set_property -dict {LOC E12  IOSTANDARD DIFF_SSTL12} [get_ports clk_250mhz_1_p]
#set_property -dict {LOC D12  IOSTANDARD DIFF_SSTL12} [get_ports clk_250mhz_1_n]
#create_clock -period 4 -name clk_250mhz_1 [get_ports clk_250mhz_1_p]

#set_property -dict {LOC AW26 IOSTANDARD DIFF_SSTL12} [get_ports clk_250mhz_2_p]
#set_property -dict {LOC AW27 IOSTANDARD DIFF_SSTL12} [get_ports clk_250mhz_2_n]
#create_clock -period 4 -name clk_250mhz_2 [get_ports clk_250mhz_2_p]

# 125 MHz
#set_property -dict {LOC AY24 IOSTANDARD LVDS} [get_ports clk_125mhz_p]
#set_property -dict {LOC AY23 IOSTANDARD LVDS} [get_ports clk_125mhz_n]
#create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# 90 MHz
set_property -dict {LOC AL20 IOSTANDARD LVCMOS18} [get_ports SYS_CLK_I]
create_clock -period 11.111 -name SYS_CLK_I [get_ports SYS_CLK_I]

# LEDs
set_property -dict {LOC AT32 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[0] }]
#  set_property -dict {LOC AV34 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[1] }]
#  set_property -dict {LOC AY30 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[2] }]
#  set_property -dict {LOC BB32 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[3] }]
#  set_property -dict {LOC BF32 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[4] }]
#  set_property -dict {LOC AU37 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[5] }]
#  set_property -dict {LOC AV36 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[6] }]
#  set_property -dict {LOC BA37 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports { LED_O[7] }]

# Reset button
# set_property -dict {LOC L19  IOSTANDARD LVCMOS12} [get_ports reset]

# Push buttons
#set_property -dict {LOC BB24 IOSTANDARD LVCMOS18} [get_ports btnu]
#set_property -dict {LOC BF22 IOSTANDARD LVCMOS18} [get_ports btnl]
#set_property -dict {LOC BE22 IOSTANDARD LVCMOS18} [get_ports btnd]
#set_property -dict {LOC BE23 IOSTANDARD LVCMOS18} [get_ports btnr]
#set_property -dict {LOC BD23 IOSTANDARD LVCMOS18} [get_ports btnc]

# DIP switches
set_property -dict {LOC B17  IOSTANDARD LVCMOS12} [get_ports {SW_I[0]}]
set_property -dict {LOC G16  IOSTANDARD LVCMOS12} [get_ports {SW_I[1]}]
#set_property -dict {LOC J16  IOSTANDARD LVCMOS12} [get_ports {SW_I[2]}]
#set_property -dict {LOC D21  IOSTANDARD LVCMOS12} [get_ports {SW_I[3]}]

# PMOD0
#  set_property -dict {LOC AY14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[0]}]
#  set_property -dict {LOC AY15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[1]}]
#  set_property -dict {LOC AW15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[2]}]
#  set_property -dict {LOC AV15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[3]}]
#  set_property -dict {LOC AV16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[4]}]
#  set_property -dict {LOC AU16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[5]}]
#  set_property -dict {LOC AT15 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[6]}]
#  set_property -dict {LOC AT16 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {pmod0[7]}]

# PMOD1
#  set_property -dict {LOC N28 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[0]}]
#  set_property -dict {LOC M30 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[1]}]
#  set_property -dict {LOC N30 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[2]}]
#  set_property -dict {LOC P30 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[3]}]
#  set_property -dict {LOC P29 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[4]}]
#  set_property -dict {LOC L31 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[5]}]
#  set_property -dict {LOC M31 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[6]}]
#  set_property -dict {LOC R29 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {pmod1[7]}]

# UART
#set_property -dict {LOC BB21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_txd]
#set_property -dict {LOC AW25 IOSTANDARD LVCMOS18} [get_ports uart_rxd]
#set_property -dict {LOC BB22 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports uart_rts]
#set_property -dict {LOC AY25 IOSTANDARD LVCMOS18} [get_ports uart_cts]

# Gigabit Ethernet SGMII PHY
#set_property -dict {LOC AU24 IOSTANDARD LVDS} [get_ports phy_sgmii_rx_p]
#set_property -dict {LOC AV24 IOSTANDARD LVDS} [get_ports phy_sgmii_rx_n]
#set_property -dict {LOC AU21 IOSTANDARD LVDS} [get_ports phy_sgmii_tx_p]
#set_property -dict {LOC AV21 IOSTANDARD LVDS} [get_ports phy_sgmii_tx_n]
#set_property -dict {LOC AT22 IOSTANDARD LVDS} [get_ports phy_sgmii_clk_p]
#set_property -dict {LOC AU22 IOSTANDARD LVDS} [get_ports phy_sgmii_clk_n]
#set_property -dict {LOC BA21 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports phy_reset_n]
#set_property -dict {LOC AR24 IOSTANDARD LVCMOS18} [get_ports phy_int_n]
#set_property -dict {LOC AR23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports phy_mdio]
#set_property -dict {LOC AV23 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports phy_mdc]

# 625 MHz ref clock from SGMII PHY
#create_clock -period 1.600 -name phy_sgmii_clk [get_ports phy_sgmii_clk_p]

# QSFP28 Interfaces
#set_property -dict {LOC Y2  } [get_ports qsfp1_rx1_p] ; # MGTYRXN0_231 GTYE3_CHANNEL_X1Y48 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC Y1  } [get_ports qsfp1_rx1_n] ; # MGTYRXP0_231 GTYE3_CHANNEL_X1Y48 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC V7  } [get_ports qsfp1_tx1_p] ; # MGTYTXN0_231 GTYE3_CHANNEL_X1Y48 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC V6  } [get_ports qsfp1_tx1_n] ; # MGTYTXP0_231 GTYE3_CHANNEL_X1Y48 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC W4  } [get_ports qsfp1_rx2_p] ; # MGTYRXN1_231 GTYE3_CHANNEL_X1Y49 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC W3  } [get_ports qsfp1_rx2_n] ; # MGTYRXP1_231 GTYE3_CHANNEL_X1Y49 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC T7  } [get_ports qsfp1_tx2_p] ; # MGTYTXN1_231 GTYE3_CHANNEL_X1Y49 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC T6  } [get_ports qsfp1_tx2_n] ; # MGTYTXP1_231 GTYE3_CHANNEL_X1Y49 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC V2  } [get_ports qsfp1_rx3_p] ; # MGTYRXN2_231 GTYE3_CHANNEL_X1Y50 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC V1  } [get_ports qsfp1_rx3_n] ; # MGTYRXP2_231 GTYE3_CHANNEL_X1Y50 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC P7  } [get_ports qsfp1_tx3_p] ; # MGTYTXN2_231 GTYE3_CHANNEL_X1Y50 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC P6  } [get_ports qsfp1_tx3_n] ;# MGTYTXP2_231 GTYE3_CHANNEL_X1Y50 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC U4  } [get_ports qsfp1_rx4_p] ; # MGTYRXN3_231 GTYE3_CHANNEL_X1Y51 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC U3  } [get_ports qsfp1_rx4_n] ;# MGTYRXP3_231 GTYE3_CHANNEL_X1Y51 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC M7  } [get_ports qsfp1_tx4_p] ; # MGTYTXN3_231 GTYE3_CHANNEL_X1Y51 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC M6  } [get_ports qsfp1_tx4_n] ; # MGTYTXP3_231 GTYE3_CHANNEL_X1Y51 / GTYE3_COMMON_X1Y12
#set_property -dict {LOC W9  } [get_ports qsfp1_mgt_refclk_0_p] ; # MGTREFCLK0P_231 from U38.4
#set_property -dict {LOC W8  } [get_ports qsfp1_mgt_refclk_0_n] ;# MGTREFCLK0N_231 from U38.5
#set_property -dict {LOC U9  } [get_ports qsfp1_mgt_refclk_1_p] ;# MGTREFCLK1P_231 from U57.28
#set_property -dict {LOC U8  } [get_ports qsfp1_mgt_refclk_1_n] ;# MGTREFCLK1N_231 from U57.29
#set_property -dict {LOC AM23 IOSTANDARD LVDS} [get_ports qsfp1_recclk_p] ;# to U57.16
#set_property -dict {LOC AM22 IOSTANDARD LVDS} [get_ports qsfp1_recclk_n] ;# to U57.17
#set_property -dict {LOC AM21 IOSTANDARD LVCMOS18} [get_ports qsfp1_modsell]
#set_property -dict {LOC BA22 IOSTANDARD LVCMOS18} [get_ports qsfp1_resetl]
#set_property -dict {LOC AL21 IOSTANDARD LVCMOS18} [get_ports qsfp1_modprsl]
#set_property -dict {LOC AP21 IOSTANDARD LVCMOS18} [get_ports qsfp1_intl]
#set_property -dict {LOC AN21 IOSTANDARD LVCMOS18} [get_ports qsfp1_lpmode]

# 156.25 MHz MGT reference clock
#create_clock -period 6.400 -name qsfp1_mgt_refclk_0 [get_ports qsfp1_mgt_refclk_0_p]

#set_property -dict {LOC T2  } [get_ports qsfp2_rx1_p] ;# MGTYRXN0_232 GTYE3_CHANNEL_X1Y52 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC T1  } [get_ports qsfp2_rx1_n] ;# MGTYRXP0_232 GTYE3_CHANNEL_X1Y52 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC L5  } [get_ports qsfp2_tx1_p] ;# MGTYTXN0_232 GTYE3_CHANNEL_X1Y52 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC L4  } [get_ports qsfp2_tx1_n] ;# MGTYTXP0_232 GTYE3_CHANNEL_X1Y52 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC R4  } [get_ports qsfp2_rx2_p] ;# MGTYRXN1_232 GTYE3_CHANNEL_X1Y53 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC R3  } [get_ports qsfp2_rx2_n] ;# MGTYRXP1_232 GTYE3_CHANNEL_X1Y53 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC K7  } [get_ports qsfp2_tx2_p] ;# MGTYTXN1_232 GTYE3_CHANNEL_X1Y53 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC K6  } [get_ports qsfp2_tx2_n] ;# MGTYTXP1_232 GTYE3_CHANNEL_X1Y53 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC P2  } [get_ports qsfp2_rx3_p] ;# MGTYRXN2_232 GTYE3_CHANNEL_X1Y54 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC P1  } [get_ports qsfp2_rx3_n] ;# MGTYRXP2_232 GTYE3_CHANNEL_X1Y54 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC J5  } [get_ports qsfp2_tx3_p] ;# MGTYTXN2_232 GTYE3_CHANNEL_X1Y54 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC J4  } [get_ports qsfp2_tx3_n] ;# MGTYTXP2_232 GTYE3_CHANNEL_X1Y54 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC M2  } [get_ports qsfp2_rx4_p] ;# MGTYRXN3_232 GTYE3_CHANNEL_X1Y55 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC M1  } [get_ports qsfp2_rx4_n] ;# MGTYRXP3_232 GTYE3_CHANNEL_X1Y55 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC H7  } [get_ports qsfp2_tx4_p] ;# MGTYTXN3_232 GTYE3_CHANNEL_X1Y55 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC H6  } [get_ports qsfp2_tx4_n] ;# MGTYTXP3_232 GTYE3_CHANNEL_X1Y55 / GTYE3_COMMON_X1Y13
#set_property -dict {LOC R9  } [get_ports qsfp2_mgt_refclk_0_p] ;# MGTREFCLK0P_232 from U104.13
#set_property -dict {LOC R8  } [get_ports qsfp2_mgt_refclk_0_n] ;# MGTREFCLK0N_232 from U104.14
#set_property -dict {LOC N9  } [get_ports qsfp2_mgt_refclk_1_p] ;# MGTREFCLK1P_232 from U57.35
#set_property -dict {LOC N8  } [get_ports qsfp2_mgt_refclk_1_n] ;# MGTREFCLK1N_232 from U57.34
#set_property -dict {LOC AP23 IOSTANDARD LVDS} [get_ports qsfp2_recclk_p] ;# to U57.12
#set_property -dict {LOC AP22 IOSTANDARD LVDS} [get_ports qsfp2_recclk_n] ;# to U57.13
#set_property -dict {LOC AN23 IOSTANDARD LVCMOS18} [get_ports qsfp2_modsell]
#set_property -dict {LOC AY22 IOSTANDARD LVCMOS18} [get_ports qsfp2_resetl]
#set_property -dict {LOC AN24 IOSTANDARD LVCMOS18} [get_ports qsfp2_modprsl]
#set_property -dict {LOC AT21 IOSTANDARD LVCMOS18} [get_ports qsfp2_intl]
#set_property -dict {LOC AT24 IOSTANDARD LVCMOS18} [get_ports qsfp2_lpmode]

# 156.25 MHz MGT reference clock
#create_clock -period 6.400 -name qsfp2_mgt_refclk_0 [get_ports qsfp2_mgt_refclk_0_p]

# I2C interface
#set_property -dict {LOC AM24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_scl]
#set_property -dict {LOC AL24 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_sda]
#set_property -dict {LOC AL25 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports i2c_mux_reset]


####################################
#
#
# FMC+
#
#
####################################


#
# QSFP3
# Bank 120 DP20-DP23
# This is the QSFP-2 in the HTG FMC schematic
# - UG1224 Table 3-8 Bank 120.
#
#  set_property PACKAGE_PIN BD42     [get_ports qsfp3_tx1_p] ; # Bank 120 - MGTYTXP0_120
#  set_property PACKAGE_PIN BD43     [get_ports qsfp3_tx1_n] ; # Bank 120 - MGTYTXN0_120
#  set_property PACKAGE_PIN BC45     [get_ports qsfp3_rx1_p] ; # Bank 120 - MGTYRXP0_120
#  set_property PACKAGE_PIN BC46     [get_ports qsfp3_rx1_n] ; # Bank 120 - MGTYRXN0_120
#  set_property PACKAGE_PIN BB42     [get_ports qsfp3_tx2_p] ; # Bank 120 - MGTYTXP1_120
#  set_property PACKAGE_PIN BB43     [get_ports qsfp3_tx2_n] ; # Bank 120 - MGTYTXN1_120
#  set_property PACKAGE_PIN BA45     [get_ports qsfp3_rx2_p] ; # Bank 120 - MGTYRXP1_120
#  set_property PACKAGE_PIN BA46     [get_ports qsfp3_rx2_n] ; # Bank 120 - MGTYRXN1_120
#  set_property PACKAGE_PIN AY42     [get_ports qsfp3_tx3_p] ; # Bank 120 - MGTYTXP2_120
#  set_property PACKAGE_PIN AY43     [get_ports qsfp3_tx3_n] ; # Bank 120 - MGTYTXN2_120
#  set_property PACKAGE_PIN AW45     [get_ports qsfp3_rx3_p] ; # Bank 120 - MGTYRXP2_120
#  set_property PACKAGE_PIN AW46     [get_ports qsfp3_rx3_n] ; # Bank 120 - MGTYRXN2_120
#  set_property PACKAGE_PIN AV42     [get_ports qsfp3_tx4_p] ; # Bank 120 - MGTYTXP3_120
#  set_property PACKAGE_PIN AV43     [get_ports qsfp3_tx4_n] ; # Bank 120 - MGTYTXN3_120
#  set_property PACKAGE_PIN AU45     [get_ports qsfp3_rx4_p] ; # Bank 120 - MGTYRXP3_120
#  set_property PACKAGE_PIN AU46     [get_ports qsfp3_rx4_n] ; # Bank 120 - MGTYRXN3_120
#  set_property PACKAGE_PIN AN40     [get_ports qsfp3_mgt_refclk_0_p] ; # Bank 120 - MGTREFCLK0P_120
#  set_property PACKAGE_PIN AN41     [get_ports qsfp3_mgt_refclk_0_n] ; # Bank 120 - MGTREFCLK0N_120
# set_property PACKAGE_PIN AM39     [get_ports "FMCP_HSPC_GBT1_5_N"] ;# Bank 120 - MGTREFCLK1N_120
# set_property PACKAGE_PIN AM38     [get_ports "FMCP_HSPC_GBT1_5_P"] ;# Bank 120 - MGTREFCLK1P_120

# QSFP2_ModselL_F D15 LA09_N AK33
# set_property -dict {LOC AK33 IOSTANDARD LVCMOS18} [get_ports qsfp3_modsell]

# QSFP2_RESET_N_F C14 LA10_P AP35
# set_property -dict {LOC AP35 IOSTANDARD LVCMOS18} [get_ports qsfp3_resetl]

# QSFP2_ModPrsl_F D14 LA09_P AJ33
# set_property -dict {LOC AJ33 IOSTANDARD LVCMOS18} [get_ports qsfp3_modprsl]

# QSFP2_IntL_F D12 LA05_N AR38
# set_property -dict {LOC AR38 IOSTANDARD LVCMOS18} [get_ports qsfp3_intl]

# QSFP2_LPMode_F C11 LA06_N AT36
# set_property -dict {LOC AT36 IOSTANDARD LVCMOS18} [get_ports qsfp3_lpmode]



#
# QSFP4
# Bank 121 DP0-DP3
# This is the QSFP1 in the HTG FMC schematic
#
#  set_property PACKAGE_PIN AT42     [get_ports qsfp4_tx1_p] ; # Bank 121 - MGTYTXP0_121
#  set_property PACKAGE_PIN AT43     [get_ports qsfp4_tx1_n] ; # Bank 121 - MGTYTXN0_121
#  set_property PACKAGE_PIN AR45     [get_ports qsfp4_rx1_p] ; # Bank 121 - MGTYRXP0_121
#  set_property PACKAGE_PIN AR46     [get_ports qsfp4_rx1_n] ; # Bank 121 - MGTYRXN0_121
#  set_property PACKAGE_PIN AP42     [get_ports qsfp4_tx2_p] ; # Bank 121 - MGTYTXP1_121
#  set_property PACKAGE_PIN AP43     [get_ports qsfp4_tx2_n] ; # Bank 121 - MGTYTXN1_121
#  set_property PACKAGE_PIN AN45     [get_ports qsfp4_rx2_p] ; # Bank 121 - MGTYRXP1_121
#  set_property PACKAGE_PIN AN46     [get_ports qsfp4_rx2_n] ; # Bank 121 - MGTYRXN1_121
#  set_property PACKAGE_PIN AM42     [get_ports qsfp4_tx3_p] ; # Bank 121 - MGTYTXP2_121
#  set_property PACKAGE_PIN AM43     [get_ports qsfp4_tx3_n] ; # Bank 121 - MGTYTXN2_121
#  set_property PACKAGE_PIN AL45     [get_ports qsfp4_rx3_p] ; # Bank 121 - MGTYRXP2_121
#  set_property PACKAGE_PIN AL46     [get_ports qsfp4_rx3_n] ; # Bank 121 - MGTYRXN2_121
#  set_property PACKAGE_PIN AL40     [get_ports qsfp4_tx4_p] ; # Bank 121 - MGTYTXP3_121
#  set_property PACKAGE_PIN AL41     [get_ports qsfp4_tx4_n] ; # Bank 121 - MGTYTXN3_121
#  set_property PACKAGE_PIN AJ45     [get_ports qsfp4_rx4_p] ; # Bank 121 - MGTYRXP3_121
#  set_property PACKAGE_PIN AJ46     [get_ports qsfp4_rx4_n] ; # Bank 121 - MGTYRXN3_121
#  set_property PACKAGE_PIN AK38     [get_ports qsfp4_mgt_refclk_0_p] ;# Bank 121 - MGTREFCLK0P_121
#  set_property PACKAGE_PIN AK39     [get_ports qsfp4_mgt_refclk_0_n] ;# Bank 121 - MGTREFCLK0N_121
# set_property PACKAGE_PIN AH38     [get_ports "FMCP_HSPC_GBT1_0_P"] ;# Bank 121 - MGTREFCLK1P_121
# set_property PACKAGE_PIN AH39     [get_ports "FMCP_HSPC_GBT1_0_N"] ;# Bank 121 - MGTREFCLK1N_121

# QSFP1_ModselL_F D11 LA05_P AP38
# set_property -dict {LOC AP38 IOSTANDARD LVCMOS18} [get_ports qsfp4_modsell]

# QSFP1_RESET_NF C10 LA06_P AT35
# set_property -dict {LOC AT35 IOSTANDARD LVCMOS18} [get_ports qsfp4_resetl]

# QSFP1_ModPrsL_F D8 LA01_CC_P AL30
# set_property -dict {LOC AL30 IOSTANDARD LVCMOS18} [get_ports qsfp4_modprsl]

# QSFP1_IntL_F D9 LA01_CC_N AL31
# set_property -dict {LOC AL31 IOSTANDARD LVCMOS18} [get_ports qsfp4_intl]

# QSFP1_LPMode_F G6 LA00_P_CC AL35
# set_property -dict {LOC AL35 IOSTANDARD LVCMOS18} [get_ports qsfp4_lpmode]



#
# QSFP5 in the verilog code
# QSFP3 in the HTG FMC schematic
# Bank 125 DP12-DP15
#
#set_property PACKAGE_PIN AC40     [get_ports qsfp5_tx1_p]
#set_property PACKAGE_PIN AC41     [get_ports qsfp5_tx1_n]
#set_property PACKAGE_PIN AC45     [get_ports qsfp5_rx1_p]
#set_property PACKAGE_PIN AC46     [get_ports qsfp5_rx1_n]
#set_property PACKAGE_PIN AA40     [get_ports qsfp5_tx2_p]
#set_property PACKAGE_PIN AA41     [get_ports qsfp5_tx2_n]
#set_property PACKAGE_PIN AB43     [get_ports qsfp5_rx2_p]
#set_property PACKAGE_PIN AB44     [get_ports qsfp5_rx2_n]
#set_property PACKAGE_PIN W40     [get_ports qsfp5_tx3_p]
#set_property PACKAGE_PIN W41     [get_ports qsfp5_tx3_n]
#set_property PACKAGE_PIN AA45     [get_ports qsfp5_rx3_p]
#set_property PACKAGE_PIN AA46     [get_ports qsfp5_rx3_n]
#set_property PACKAGE_PIN U40     [get_ports qsfp5_tx4_p]
#set_property PACKAGE_PIN U41     [get_ports qsfp5_tx4_n]
#set_property PACKAGE_PIN Y43     [get_ports qsfp5_rx4_p]
#set_property PACKAGE_PIN Y44     [get_ports qsfp5_rx4_n]
#set_property PACKAGE_PIN AB38     [get_ports qsfp5_mgt_refclk_0_p]
#set_property PACKAGE_PIN AB39     [get_ports qsfp5_mgt_refclk_0_n]

# QSFP3_ModselL_F C18 LA14_P AG31
#set_property -dict {LOC AG31 IOSTANDARD LVCMOS18} [get_ports qsfp5_modsell]

# QSFP3_RESET_NF C19 LA14_N AH31
#set_property -dict {LOC AH31 IOSTANDARD LVCMOS18} [get_ports qsfp5_resetl]

# QSFP3_ModPrsL_F D18 LA13_N AJ36
#set_property -dict {LOC AJ36 IOSTANDARD LVCMOS18} [get_ports qsfp5_modprsl]

# QSFP3_IntL_F D17 LA13_P AJ35
#set_property -dict {LOC AJ35 IOSTANDARD LVCMOS18} [get_ports qsfp5_intl]

# QSFP3_LPMode_F C15 LA10_N AR35
#set_property -dict {LOC AR35 IOSTANDARD LVCMOS18} [get_ports qsfp5_lpmode]



#
# QSFP6 in the verilog code
# QSFP4 in the HTG FMC schematic
# Bank 122 DP8-DP11
#
#set_property PACKAGE_PIN AK42     [get_ports qsfp6_tx1_p]
#set_property PACKAGE_PIN AK43     [get_ports qsfp6_tx1_n]
#set_property PACKAGE_PIN AG45     [get_ports qsfp6_rx1_p]
#set_property PACKAGE_PIN AG46     [get_ports qsfp6_rx1_n]
#set_property PACKAGE_PIN AJ40     [get_ports qsfp6_tx2_p]
#set_property PACKAGE_PIN AJ41     [get_ports qsfp6_tx2_n]
#set_property PACKAGE_PIN AF43     [get_ports qsfp6_rx2_p]
#set_property PACKAGE_PIN AF44     [get_ports qsfp6_rx2_n]
#set_property PACKAGE_PIN AG40     [get_ports qsfp6_tx3_p]
#set_property PACKAGE_PIN AG41     [get_ports qsfp6_tx3_n]
#set_property PACKAGE_PIN AE45     [get_ports qsfp6_rx3_p]
#set_property PACKAGE_PIN AE46     [get_ports qsfp6_rx3_n]
#set_property PACKAGE_PIN AE40     [get_ports qsfp6_tx4_p]
#set_property PACKAGE_PIN AE41     [get_ports qsfp6_tx4_n]
#set_property PACKAGE_PIN AD43     [get_ports qsfp6_rx4_p]
#set_property PACKAGE_PIN AD44     [get_ports qsfp6_rx4_n]
#set_property PACKAGE_PIN AF38     [get_ports qsfp6_mgt_refclk_0_p]
#set_property PACKAGE_PIN AF39     [get_ports qsfp6_mgt_refclk_0_n]

# QSFP4_ModselL_F H14 LA07_N AP37
#set_property -dict {LOC AP37 IOSTANDARD LVCMOS18} [get_ports qsfp6_modsell]

# QSFP4_RESET_NF G15 LA12_P AH33
#set_property -dict {LOC AH33 IOSTANDARD LVCMOS18} [get_ports qsfp6_resetl]

# QSFP4_ModPrsL_F H13 LA07_P AP36
#set_property -dict {LOC AP36 IOSTANDARD LVCMOS18} [get_ports qsfp6_modprsl]

# QSFP4_IntL_F G13 LA08_N AK30
#set_property -dict {LOC AK30 IOSTANDARD LVCMOS18} [get_ports qsfp6_intl]

# QSFP4_LPMode_F G12 LA08_P AK29
#set_property -dict {LOC AK29 IOSTANDARD LVCMOS18} [get_ports qsfp6_lpmode]



#
# QSFP7 in the verilog code
# QSFP5 in the HTG FMC schematic
# Bank 127 DP16-DP19
# Table 3-13
#
set_property PACKAGE_PIN H42     [get_ports qsfp7_tx1_p]
#set_property PACKAGE_PIN H43     [get_ports qsfp7_tx1_n]
set_property PACKAGE_PIN L45     [get_ports qsfp7_rx1_p]
#set_property PACKAGE_PIN L46     [get_ports qsfp7_rx1_n]
set_property PACKAGE_PIN F42     [get_ports qsfp7_tx2_p]
#set_property PACKAGE_PIN F43     [get_ports qsfp7_tx2_n]
set_property PACKAGE_PIN J45     [get_ports qsfp7_rx2_p]
#set_property PACKAGE_PIN J46     [get_ports qsfp7_rx2_n]
set_property PACKAGE_PIN D42     [get_ports qsfp7_tx3_p]
#set_property PACKAGE_PIN D43     [get_ports qsfp7_tx3_n]
set_property PACKAGE_PIN G45     [get_ports qsfp7_rx3_p]
#set_property PACKAGE_PIN G46     [get_ports qsfp7_rx3_n]
set_property PACKAGE_PIN B42     [get_ports qsfp7_tx4_p]
#set_property PACKAGE_PIN B43     [get_ports qsfp7_tx4_n]
set_property PACKAGE_PIN E45     [get_ports qsfp7_rx4_p]
#set_property PACKAGE_PIN E46     [get_ports qsfp7_rx4_n]
set_property PACKAGE_PIN R40     [get_ports qsfp7_mgt_refclk_0_p]
#set_property PACKAGE_PIN R41     [get_ports qsfp7_mgt_refclk_0_n]

# QSFP5_ModselL_F G10 LA03_N AT40
set_property -dict {LOC AT40 IOSTANDARD LVCMOS18} [get_ports qsfp7_modsell]

# QSFP5_RESET_NF H11 LA04_N AT37
set_property -dict {LOC AT37 IOSTANDARD LVCMOS18} [get_ports qsfp7_resetl]

# QSFP5_ModPrsL_F H17 LA11_N AJ31
set_property -dict {LOC AJ31 IOSTANDARD LVCMOS18} [get_ports qsfp7_modprsl]

# QSFP5_IntL_F H16 LA11_P AJ30
set_property -dict {LOC AJ30 IOSTANDARD LVCMOS18} [get_ports qsfp7_intl]

# QSFP5_LPMode_F G16 LA12_N AH34
set_property -dict {LOC AH34 IOSTANDARD LVCMOS18} [get_ports qsfp7_lpmode]



#
# QSFP8 in the verilog code
# QSFP6 in the HTG FMC schematic
# Bank 126 DP4-DP7
#
#set_property PACKAGE_PIN T42     [get_ports qsfp8_tx1_p]
#set_property PACKAGE_PIN T43     [get_ports qsfp8_tx1_n]
#set_property PACKAGE_PIN W45     [get_ports qsfp8_rx1_p]
#set_property PACKAGE_PIN W46     [get_ports qsfp8_rx1_n]
#set_property PACKAGE_PIN P42     [get_ports qsfp8_tx2_p]
#set_property PACKAGE_PIN P43     [get_ports qsfp8_tx2_n]
#set_property PACKAGE_PIN U45     [get_ports qsfp8_rx2_p]
#set_property PACKAGE_PIN U46     [get_ports qsfp8_rx2_n]
#set_property PACKAGE_PIN M42     [get_ports qsfp8_tx3_p]
#set_property PACKAGE_PIN M43     [get_ports qsfp8_tx3_n]
#set_property PACKAGE_PIN R45     [get_ports qsfp8_rx3_p]
#set_property PACKAGE_PIN R46     [get_ports qsfp8_rx3_n]
#set_property PACKAGE_PIN K42     [get_ports qsfp8_tx4_p]
#set_property PACKAGE_PIN K43     [get_ports qsfp8_tx4_n]
#set_property PACKAGE_PIN N45     [get_ports qsfp8_rx4_p]
#set_property PACKAGE_PIN N46     [get_ports qsfp8_rx4_n]
#set_property PACKAGE_PIN V38     [get_ports qsfp8_mgt_refclk_0_p]
#set_property PACKAGE_PIN V39     [get_ports qsfp8_mgt_refclk_0_n]

# QSFP6_ModselL_F H7 LA02_P AJ32
#set_property -dict {LOC AJ32 IOSTANDARD LVCMOS18} [get_ports qsfp8_modsell]

# QSFP6_RESET_NF G7 LA00_N_CC AL36
#set_property -dict {LOC AL36 IOSTANDARD LVCMOS18} [get_ports qsfp8_resetl]

# QSFP6_ModPrsL_F H8 LA02_N AK32
#set_property -dict {LOC AK32 IOSTANDARD LVCMOS18} [get_ports qsfp8_modprsl]

# QSFP6_IntL_F G9 LA03_P AT39
#set_property -dict {LOC AT39 IOSTANDARD LVCMOS18} [get_ports qsfp8_intl]

# QSFP6_LPMode_F H10 LA04_P AR37
#set_property -dict {LOC AR37 IOSTANDARD LVCMOS18} [get_ports qsfp8_lpmode]

# LOL=loss of lock
# CLK_LOL_N_F G19 LA16_N AH35
#set_property -dict {LOC AH35 IOSTANDARD LVCMOS18} [get_ports clk_lol]
