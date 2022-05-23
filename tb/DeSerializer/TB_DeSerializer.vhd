----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_DeSerializer - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the batch DeSerialzers.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_DESERIALIZER is
  --  Port ( );
end entity TB_DESERIALIZER;

architecture TB of TB_DESERIALIZER is

  constant CKTIME          : time := 10 ns;

  procedure load_and_store (
    constant W     : integer;
    constant value : SLVArray;
    signal input   : out  SLVArray;
    signal store   : out  std_logic;
    signal load    : out  std_logic
  ) is
  begin

    store <= '0';
    load  <= '1';
    input <= value;
    wait for CKTIME;
    load  <= '0';
    wait for (W) * CKTIME;
    store <= '1';
    wait for CKTIME;
    store <= '0';

  end procedure load_and_store;

  procedure assert_equivalence (
    constant N    : integer;
    signal input  : in  SLVArray;
    signal output : in  SLVArray
  ) is
  begin

    for i in 0 to N - 1 loop

      assert (input(i) = output(i))
        report "Mismatch:: " &
               " Input      = " & integer'image(to_integer(unsigned(input(i)))) &
               " Output     = " & integer'image(to_integer(unsigned(output(i)))) &
               " Expectation= " & integer'image(to_integer(unsigned(input(i))));

    end loop;

  end procedure assert_equivalence;

  constant W               : integer := 8;
  constant N               : integer := 4;

  signal clk               : std_logic;
  signal rst               : std_logic;
  signal e_i               : std_logic;
  signal store_i           : std_logic;
  signal load_i            : std_logic;

  signal input_i           : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal inter_i           : std_logic_vector(0 to N - 1);
  signal output_i          : SLVArray(0 to N - 1)(W - 1 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  SERIALIZER_SR_1 : entity work.serializer_sr
    generic map (
      N => N,
      W => W
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      LOAD       => load_i,
      PAR_INPUT  => input_i,
      SER_OUTPUT => inter_i
    );

  DESERIALIZER_SR_1 : entity work.deserializer_sr
    generic map (
      N => N,
      W => W
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      STORE      => store_i,
      SER_INPUT  => inter_i,
      PAR_OUTPUT => output_i
    );

  TEST_STIM : process is
  begin

    rst <= '1';
    e_i <= '0';
    wait for CKTIME / 2;
    e_i <= '1';
    rst <= '0';
    load_and_store (
      W     => W,
      value => (X"A2", X"DF", X"04", X"33"),
      input => input_i,
      store => store_i,
      load  => load_i);
    wait;

  end process TEST_STIM;

  TEST_ASSER : process is
  begin

    wait for 3 * CKTIME / 2;
    wait for CKTIME * (W+1);
    assert_equivalence (
      N      => N,
      input  => input_i,
      output => output_i);
    wait;

  end process TEST_ASSER;

end architecture TB;
