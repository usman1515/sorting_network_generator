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

  constant W                 : integer := 8;
  constant DEPTH             : integer := 3;
  constant N                 : integer := 8;

  constant CKTIME            : time := 10 ns;
  signal   clk               : std_logic;

  constant SEED_I            : std_logic_vector(W - 1 downto 0) := "10110001";
  constant P_I               : std_logic_vector(W - 1 downto 0) := "01101010";

  signal rst_i               : std_logic;
  signal e_i                 : std_logic;

  signal e_delayed_i         : std_logic_vector(2 downto 0);
  -- Output of LFSRs
  signal rand_data_i         : SLVArray(N / W - 1 downto 0)(W - 1 downto 0);
  -- Output of Round-Robin DMUXs
  signal unsorted_data_i     : SLVArray(N - 1 downto 0)(W - 1 downto 0);
  -- Output of Sorting Network
  signal sorted_data_i       : SLVArray(N - 1 downto 0)(W - 1 downto 0);

  signal valid_i             : std_logic;

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  TEST_PROCESS : process is

  begin

    e_i   <= '0';
    wait for CKTIME / 2;
    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';
    e_i   <= '1';
    wait for (W) * CKTIME;

    wait;

  end process TEST_PROCESS;

  INPUT : for i in 0 to N / W - 1 generate

    LFSR_1 : entity work.lfsr
      generic map (
        W => W,
        POLY => P_I
      )
      port map (
        CLK    => clk,
        E      => e_i,
        RST    => rst_i,
        SEED   => SEED_I,
        OUTPUT => rand_data_i(i)
      );

    RRDMUX_NXW_1 : entity work.rr_dmux_nxw
      generic map (
        W => W,
        N => W
      )
      port map (
        CLK    => clk,
        E      => e_i,
        RST    => rst_i,
        INPUT  => rand_data_i(i),
        OUTPUT => unsorted_data_i((i + 1)*W - 1 downto i*W)
      );

  end generate INPUT;

  ENABLEDELAY_1 : entity work.shift_register
    generic map (
      W => W - 1
    )
    port map (
      CLK   => clk,
      E     => not rst_i,
      RST   => rst_i,
      SER_INPUT  => e_i,
      SER_OUTPUT => e_delayed_i(0)
    );

  SORTNET : entity work.ODDEVEN_8_TO_8_MAX
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_delayed_i(0),
      RST    => rst_i,
      INPUT  => unsorted_data_i,
      OUTPUT => sorted_data_i
    );

  ENABLEDELAY_2 : entity work.shift_register
    generic map (
      W => W + DEPTH + 1
    )
    port map (
      CLK   => clk,
      E     => not rst_i,
      RST   => rst_i,
      SER_INPUT  => e_delayed_i(0),
      SER_OUTPUT => e_delayed_i(1)
    );

  VALIDATOR_1 : entity work.validator
    generic map (
      W => W,
      N => N
    )
    port map (
      CLK   => clk,
      E     => e_delayed_i(1),
      RST   => rst_i,
      INPUT => sorted_data_i,
      VALID => valid_i
    );

end architecture TB;
