----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_MUX_2X2 - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the different MUX_2X2 implementations.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity TB_MUX_2X2 is
  --  Port ( );
end entity TB_MUX_2X2;

architecture TB of TB_MUX_2X2 is

  constant CKTIME      : time := 10 ns;

  procedure assert_equivalence (
    signal input     : in  std_logic_vector;
    signal sel       : in  std_logic_vector;
    signal reference : in  std_logic_vector;
    signal value     : in  std_logic_vector
  ) is
  begin

    assert (value = reference)
      report "Mismatch:: " &
             " Input      = " & integer'image(to_integer(unsigned(input))) &
             " sel        = " & integer'image(to_integer(unsigned(sel))) &
             " Output     = " & integer'image(to_integer(unsigned(value))) &
             " Expectation= " & integer'image(to_integer(unsigned(reference)));

  end procedure assert_equivalence;

  signal clk           : std_logic;
  signal enable        : std_logic;
  signal input_i       : std_logic_vector(1 downto 0);
  signal sel_i         : std_logic_vector(0 downto 0);
  signal output0_i     : std_logic_vector(1 downto 0);
  signal output1_i     : std_logic_vector(1 downto 0);
  signal output2_i     : std_logic_vector(1 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  MUX_2X2_1 : entity work.mux_2x2
    port map (
      A0  => input_i(0),
      B0  => input_i(1),
      SEL => sel_i(0),
      A1  => output0_i(0),
      B1  => output0_i(1)
    );

  MUX_2X2_PRIMITIVE_1 : entity work.mux_2x2_primitive
    port map (
      A0  => input_i(0),
      B0  => input_i(1),
      SEL => sel_i(0),
      A1  => output1_i(0),
      B1  => output1_i(1)
    );

  MUX_2X2_SYNC_1 : entity work.mux_2x2_sync
    port map (
      CLK => clk,
      E   => enable,
      A0  => input_i(0),
      B0  => input_i(1),
      SEL => sel_i(0),
      A1  => output2_i(0),
      B1  => output2_i(1)
    );

  TEST_PROCESS : process is
  begin
    enable <= '1';
    wait for  CKTIME;

    for i in 0 to 1 loop

      for j in 0 to 3 loop

        input_i <= std_logic_vector(to_unsigned(j, 2));
        sel_i   <= std_logic_vector(to_unsigned(i, 1));
        wait for CKTIME;
        assert_equivalence (
          input     => input_i,
          sel       => sel_i,
          reference => output0_i,
          value     => output1_i);
        assert_equivalence (
          input     => input_i,
          sel       => sel_i,
          reference => output0_i,
          value     => output2_i);

      end loop;

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture TB;
