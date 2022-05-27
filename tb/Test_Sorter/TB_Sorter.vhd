----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_Sorter - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for a test sorter with a sorting network with 16 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_SORTER is
end entity TB_SORTER;

architecture TB of TB_SORTER is

  constant CKTIME  : time := 10 ns;
  signal   clk     : std_logic;

  constant W       : integer := 8;
  signal   rst_i   : std_logic; -- Debounced reset signal.
  signal   e_i     : std_logic; -- Debounced enable signal.
  signal   valid_i : std_logic;

begin

  TEST_SORTER_X_1 : entity work.test_sorter_x
    generic map (
      W => W
    )
    port map (
      CLK   => clk,
      RST   => rst_i,
      E     => e_i,
      VALID => valid_i
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

    e_i   <= '0';
    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';
    e_i   <= '1';
    wait for 10 * W * CKTIME;

    wait;

  end process SIGNAL_PROCESS;

  ASSERT_PROCESS : process is
  begin

    wait for 10 * W * CKTIME;

    wait;

  end process ASSERT_PROCESS;

end architecture TB;
