----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_TEST_Sorter - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for a test sorter with a sorting network with 16 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_TEST_SORTER is
end entity TB_TEST_SORTER;

architecture TB of TB_TEST_SORTER is

  constant CKTIME     : time := 10 ns;
  signal   clk        : std_logic;

  signal   rst        : std_logic; -- Debounced reset signal.
  signal   enable     : std_logic; -- Debounced enable signal.
  signal   in_order      : std_logic;

begin

  TEST_SORTER_1 : entity work.test_sorter
    port map (
      CLK_I    => clk,
      RST_I    => rst,
      ENABLE_I => enable,
      IN_ORDER_O  => in_order
    );

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  SIGNAL_PROCESS : process is

  begin

    enable <= '0';
    rst    <= '1';
    wait for CKTIME;
    rst    <= '0';
    enable <= '1';

    wait;

  end process SIGNAL_PROCESS;

end architecture TB;
