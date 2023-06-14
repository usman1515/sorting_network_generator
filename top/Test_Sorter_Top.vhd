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
    SYS_CLK : in  std_logic;
    SW_RST  : in  std_logic;
    SW_EN   : in  std_logic;
    LED     : out std_logic
    );
end entity TEST_SORTER_TOP;

architecture STRUCTURAL of TEST_SORTER_TOP is

  signal reset  : std_logic;            -- Debounced reset signal.
  signal enable : std_logic;            -- Debounced enable signal.

begin


  RESETDEBOUNCER : entity work.debouncer
    generic map (
      TIMEOUT_CYCLES => 50
      )
    port map (
      CLK_I    => SYS_CLK,
      RST_I    => '0',
      INPUT_I  => SW_RST,
      OUTPUT_O => reset
      );

  ENABLEDEBOUNCER : entity work.debouncer
    generic map (
      TIMEOUT_CYCLES => 50
      )
    port map (
      CLK_I    => SYS_CLK,
      RST_I    => '0',
      INPUT_I  => SW_EN,
      OUTPUT_O => enable
      );

  TEST_SORTER_1 : entity work.test_sorter
    port map (
      CLK_I      => SYS_CLK,
      RST_I      => reset,
      ENABLE_I   => enable,
      IN_ORDER_O => LED
      );

end architecture STRUCTURAL;
