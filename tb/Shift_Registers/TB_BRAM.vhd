--------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the different implementation of shift registers.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_BRAM is
end entity TB_BRAM;

architecture TB of TB_BRAM is

  constant CKTIME              : time := 10 ns;

  constant W                   : integer := 8;

  signal clk                   : std_logic;
  signal rst                   : std_logic;
  signal e_i                   : std_logic;
  signal load_i                : std_logic;

  signal bram                  : std_logic;

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  BRAM_1 : entity work.serializer_bram
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      LOAD       => load_i,
      PAR_INPUT  => "10101010",
      SER_OUTPUT => bram
    );

  TEST_STIM : process is
  begin
  wait for CKTIME/2;
    rst    <= '1';
    load_i <= '0';
  wait for CKTIME;
    load_i <= '1';
    rst    <= '0';
    e_i    <= '1';

  wait for CKTIME;
    load_i <= '0';
    wait;

  end process TEST_STIM;


end architecture TB;
