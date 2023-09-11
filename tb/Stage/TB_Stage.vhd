----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: Mon Jul 24 10:43:35 2023
-- Design Name:
-- Module Name: TB_Stage - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for a sorting network stage.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity TB_Stage is
end entity TB_Stage;

architecture TB of TB_Stage is

  constant CKTIME : time := 10 ns;
  signal clk      : std_logic;

  constant W         : integer     := 8;
  constant N         : integer     := 8;
  constant SW        : integer     := 1;
  constant PERM      : Permutation := (0, 1, 5, 4, 3, 2, 6, 7);
  constant NUM_DELAY : integer     := 4;
  constant NUM_START       : integer := 2;
  constant NUM_ENABLE      : integer := 2;
  constant NUM_DSP         : integer := 1;
  constant NUM_REG_PER_DSP : integer := 2;

  signal rst    : std_logic;            -- Debounced reset signal.
  signal enable : std_logic_vector(0 to NUM_ENABLE-1);  -- Debounced enable signal.
  signal start  : std_logic_vector(0 to NUM_START-1);  -- Debounced enable signal.

  signal stream_o, stream_i : SLVArray(0 to N -1)(SW-1 downto 0);


  signal data_output : SLVArray(0 to N-1)(W-1 downto 0);
  signal data_input  : SLVArray(0 to N-1)(W-1 downto 0);

begin
  Stage_1 : entity work.Stage
    generic map (
      N               => N,
      SW              => SW,
      PERM            => PERM,
      NUM_DELAY       => NUM_DELAY,
      NUM_START       => NUM_START,
      NUM_ENABLE      => NUM_ENABLE,
      NUM_DSP         => NUM_DSP,
      NUM_REG_PER_DSP => NUM_REG_PER_DSP)
    port map (
      CLK_I    => clk,
      RST_I    => rst,
      ENABLE_I => enable,
      START_I  => start,
      STREAM_I => stream_i,
      STREAM_O => stream_o);

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  STIMULUS : process is
  begin

    enable <= (others => '0');
    rst    <= '1';
    start  <= (others => '1');
    for i in 0 to N-1 loop
      data_input(i) <= std_logic_vector(to_unsigned(PERM(i), W));
    end loop;
    wait for CKTIME;
    rst    <= '0';
    enable <= (others => '1');
    start  <= (others => '1');
    for i in W/SW-1 downto 0 loop
      for j in 0 to N-1 loop
        stream_i(j) <= data_input(j)((i+1)*SW-1 downto i*SW);
      end loop;
      wait for CKTIME;
      start <= (others => '0');
    end loop;
    wait for CKTIME;
    wait;
  end process STIMULUS;

  TEST : process is
  begin
    data_output <= (others => (others => '0'));
    wait for 2*CKTIME;
    for i in W/SW-1 downto 0 loop
      for j in 0 to N-1 loop
        data_output(j)((i+1)*SW-1 downto i*SW) <= stream_o(j);
      end loop;
      wait for CKTIME;
    end loop;
    wait for CKTIME;

    for i in 0 to N-1 loop
      assert to_integer(unsigned(data_output(i))) = i;
    end loop;
    wait;

  end process TEST;

end architecture TB;
