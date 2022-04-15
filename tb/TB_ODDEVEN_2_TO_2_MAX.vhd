----------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_ODDEVEN_2_TO_2_MAX - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for synchronous ODDEVEN_2_TO_2_MAX sorting network with 2 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_ODDEVEN_2_TO_2_MAX is
end entity TB_ODDEVEN_2_TO_2_MAX;

architecture TB of TB_ODDEVEN_2_TO_2_MAX is

  constant W           : integer := 8;
  constant N           : integer := 2;
  constant DEPTH       : integer := 1;

  constant CKTIME      : time := 10 ns;
  signal   clk         : std_logic;

  signal rst_i         : std_logic;
  signal e_i           : std_logic;

  signal a_sorted_i    : SLVArray(1 downto 0)(W - 1 downto 0);
  signal a0_i          : SLVArray(1 downto 0)(W - 1 downto 0);
  signal a1_i          : SLVArray(1 downto 0)(W - 1 downto 0);

begin

  ODDEVEN_2_1 : entity work.ODDEVEN_2_TO_2_MAX
    generic map (
      W     => W,
      DEPTH => DEPTH,
      N     => N
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => a1_i
    );

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  TEST_PROCESS : process is

  begin
    a_sorted_i <= (others => (others => '0'));
    e_i        <= '0';
    wait for CKTIME / 2;
    rst_i      <= '1';
    a0_i       <= (X"2B", X"A8");
    wait for CKTIME;
    rst_i      <= '0';
    e_i        <= '1';
    wait for (W) * CKTIME;
    a_sorted_i <= (X"A8", X"2B");
    a0_i       <= (X"F1", X"F2");

    wait for 2 * CKTIME;

    for i in 0 to 1 loop

      assert a1_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_i(i)=   " & integer'image(to_integer(unsigned(a1_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  a1_i(i) = A_Sorted_i(i)";

    end loop;

    wait for CKTIME;
    a_sorted_i <= (X"F2", X"F1");

    wait for W * CKTIME;

    for i in 0 to 1 loop

      assert a1_i(i) = a_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(a1_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted_i(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture TB;
