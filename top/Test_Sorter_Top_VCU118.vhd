----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Sorter_Top - STRUCTURAL
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Top module for implementation of a Test Sorter on Zedboard Rev. C
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity TEST_SORTER_TOP is
  port (
    SYSCLK1_300_P : in  std_logic;
    SYSCLK1_300_N : in  std_logic;
    GPIO_DIP_SW1  : in  std_logic;
    GPIO_DIP_SW2  : in  std_logic;
    GPIO_LED0     : out std_logic
    );
end entity TEST_SORTER_TOP;

architecture STRUCTURAL of TEST_SORTER_TOP is

  signal reset  : std_logic;            -- Debounced reset signal.
  signal enable : std_logic;            -- Debounced enable signal.
  signal clk    : std_logic;
begin

  xlnx_clk_gen_1 : entity xlnx_clk_gen
    port map (
      clk_out1 => clk,
      reset    => GPIO_DIP_SW1,
      locked   => open,
      clk_in1_p  => SYSCLK1_300_P,
      clk_in1_n  => SYSCLK1_300_N
      );

  RESETDEBOUNCER : entity work.debouncer
    generic map (
      TIMEOUT_CYCLES => 50
      )
    port map (
      CLK_I    => SYSCLK1_300_P,
      RST_I    => '0',
      INPUT_I  => GPIO_DIP_SW1,
      OUTPUT_O => reset
      );

  ENABLEDEBOUNCER : entity work.debouncer
    generic map (
      TIMEOUT_CYCLES => 50
      )
    port map (
      CLK_I    => SYSCLK1_300_P,
      RST_I    => '0',
      INPUT_I  => GPIO_DIP_SW2,
      OUTPUT_O => enable
      );

  TEST_SORTER_1 : entity work.test_sorter
    port map (
      CLK_I      => SYSCLK1_300_P,
      RST_I      => reset,
      ENABLE_I   => enable,
      IN_ORDER_O => GPIO_LED0
      );

end architecture STRUCTURAL;
