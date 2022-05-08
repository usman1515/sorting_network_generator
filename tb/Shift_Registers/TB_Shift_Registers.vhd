--------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_Shift_Registers - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the different implementation of shift registers.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_SHIFT_REGISTERS is
end entity TB_SHIFT_REGISTERS;

architecture TB of TB_SHIFT_REGISTERS is

  constant CKTIME           : time := 10 ns;

  procedure serialize (
    constant W_i   : in integer;
    constant value : in std_logic_vector;
    signal serial  : out std_logic_vector
  ) is
  begin

    for i in W_i - 1  downto 0 loop

      for j in serial'high downto serial'low loop

        serial(j) <= value(i);

      end loop;

      wait for CKTIME;

    end loop;

  end procedure serialize;

  procedure deserialize (
    constant W_i  : in integer;
    signal serial : in std_logic;
    signal value  : out std_logic_vector
  ) is
  begin

    for i in 0 to W_i - 1 loop

      value(i) <= serial;
      --      for j in serial'high -1 downto serial'low loop
      --        assert (serial(serial'high) = serial(j))
      --          report "Mismatch:: " &
      --                 "serial(" & integer'image(serial'high) & ")= " &
      --                         integer'image(to_integer(unsigned(serial(serial'high)))) &
      --                 "serial("& integer'image(i) &")= " &
      --                         integer'image(to_integer(unsigned(serial(j)))) &
      --                 "Expected equality.";
      --      end loop;
      wait for CKTIME;

    end loop;

  end procedure deserialize;

  procedure assert_equal (
    signal value0 : in std_logic_vector;
    signal value1 : in std_logic_vector
  ) is
  begin

    assert (value0 = value1)
      report "Mismatch:: " &
             " value0 " & integer'image(to_integer(unsigned(value0))) &
             " value1= " & integer'image(to_integer(unsigned(value1))) &
             " Expectation value0 = value1";

  end procedure assert_equal;

  constant W                : integer := 8;
  constant N                : integer := 1;

  signal clk                : std_logic;
  signal rst                : std_logic;
  signal e_i                : std_logic;

  signal serial_input       : std_logic_vector(N - 1 downto 0);

  signal serial_reference   : std_logic_vector(N - 1 downto 0);
  signal reference          : std_logic_vector(W - 1 downto 0);

  signal serial_dsp         : std_logic_vector(N - 1 downto 0);

  signal inter_dsp          : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal dsp                : std_logic_vector(W - 1 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  SR : for i in N - 1 downto 0 generate

    SHIFT_REGISTER_1 : entity work.shift_register
      generic map (
        W => W
      )
      port map (
        CLK        => clk,
        RST        => rst,
        E          => e_i,
        SER_INPUT  => serial_input(i),
        SER_OUTPUT => serial_reference(i)
      );

  end generate SR;

  DSP_SR : for i in N - 1 downto 0 generate

    REGISTER_DSP_1 : entity work.register_dsp
      generic map (
        NUM_INPUT => W
      )
      port map (
        CLK        => clk,
        RST        => rst,
        E          => e_i,
        REG_INPUT  => inter_dsp(i)( W - 2 downto 0) & serial_input(i),
        REG_OUTPUT => inter_dsp(i)
      );

  serial_dsp (i) <= inter_dsp(i)(W-1);

  end generate DSP_SR;

  TEST_STIM : process is
  begin

    rst <= '1';
    wait for CKTIME;
    rst <= '0';
    e_i <= '1';

    serialize(W, X"56", serial_input);

    wait;

  end process TEST_STIM;

  TEST_ASSERT_REF : process is
  begin

    reference <= (others => '0');
    wait for CKTIME;
    wait for (W) * CKTIME;

    deserialize(W, serial_reference(0), reference);
    wait for CKTIME;
    assert (reference = X"56")
      report "Mismatch:: " &
             " value0 " & integer'image(to_integer(unsigned(reference))) &
             " value1= " & integer'image(86) &
             " Expectation value0 = value1";

    wait;

  end process TEST_ASSERT_REF;

  TEST_ASSERT_DSP : process is
  begin

    dsp <= (others => '0');
    wait for CKTIME;
    wait for (W ) * CKTIME;
    deserialize(W, serial_dsp(0), dsp);
    wait for CKTIME;
    assert_equal(dsp, reference);

    wait;

  end process TEST_ASSERT_DSP;

end architecture TB;
