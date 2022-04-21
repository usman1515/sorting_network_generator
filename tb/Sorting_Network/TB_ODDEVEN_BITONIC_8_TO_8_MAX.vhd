----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_ODDEVEN_8 - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for synchronous ODDEVEN_8 sorting network with 8 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_ODDEVEN_BITONIC_8_TO_8_MAX is
end entity TB_ODDEVEN_BITONIC_8_TO_8_MAX;

architecture TB of TB_ODDEVEN_BITONIC_8_TO_8_MAX is

  constant W               : integer := 8;
  constant DEPTH           : integer := 6;
  constant N               : integer := 8;
  constant M               : integer := 8;

  constant CKTIME          : time := 10 ns;
  signal   clk             : std_logic;

  signal rst_i             : std_logic;
  signal e_i               : std_logic;

  signal a0_i              : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal a_sorted_i        : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal a1_oe_i           : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal a1_b_i            : SLVArray(0 to M - 1)(W - 1 downto 0);

begin

  ODDEVEN_8_1 : entity work.oddeven_8_to_8_max
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => a1_oe_i
    );

  BITONIC_8_1 : entity work.bitonic_8_to_8_max
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => a1_b_i
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

    wait for CKTIME / 2;
    e_i   <= '0';
    rst_i <= '1';
    wait for CKTIME;
    a0_i  <= (X"2B", X"A8", X"F2", X"5C", X"2B", X"F8", X"41", X"73");
    rst_i <= '0';
    e_i   <= '1';
    wait for W * CKTIME;
    a0_i  <= (X"12", X"48", X"B2", X"5C", X"2B", X"A8", X"C2", X"5C");

    wait for W * CKTIME;

    wait;

  end process SIGNAL_PROCESS;

  ASSERT_PROCESS : process is
  begin

    a_sorted_i <= (others => (others => '0'));
    wait for CKTIME / 2;
    a_sorted_i <= (X"F8", X"F2", X"A8", X"73", X"5C", X"41", X"2B", X"2B");
    wait for CKTIME;
    wait for W * CKTIME;
    wait for W * CKTIME;

    for i in 0 to N - 1 loop

      assert a1_oe_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_oe_i(i)=   " & integer'image(to_integer(unsigned(a1_oe_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  a1_oe_i(i) = A_Sorted_i(i)";

    end loop;

    for i in 0 to N - 1 loop

      assert a1_b_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_b_i(i)=   " & integer'image(to_integer(unsigned(a1_b_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  a1_b_i(i) = A_Sorted_i(i)";

    end loop;

    a_sorted_i <= (X"C2", X"B2", X"A8", X"5C", X"5C", X"48", X"2B", X"12");
    wait for W * CKTIME;

    for i in 0 to N - 1 loop

      assert a1_oe_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_oe_i(i)=   " & integer'image(to_integer(unsigned(a1_oe_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  a1_oe_i(i) = A_Sorted_i(i)";

    end loop;

    for i in 0 to N - 1 loop

      assert a1_b_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_b_i(i)=   " & integer'image(to_integer(unsigned(a1_b_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  a1_b_i(i) = A_Sorted_i(i)";

    end loop;

    wait;

  end process ASSERT_PROCESS;

end architecture TB;
