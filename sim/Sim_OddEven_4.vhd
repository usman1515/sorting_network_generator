----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SIM_ODDEVEN_4 - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for synchronous ODDEVEN_4 sorting network with 4 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity SIM_ODDEVEN_4 is
end entity SIM_ODDEVEN_4;

architecture BEHAVIORAL of SIM_ODDEVEN_4 is

  constant W           : integer := 8;
  constant DEPTH       : integer := 3;
  constant N           : integer := 4;

  constant CKTIME      : time := 10 ns;
  signal   clk         : std_logic;

  signal rst_i         : std_logic;
  signal e_i           : std_logic;

  constant A_SORTED_I  : SLVArray(3 downto 0)(W - 1 downto 0) := (X"F2", X"A8", X"5C", X"2B");
  signal   a0_i        : SLVArray(3 downto 0)(W - 1 downto 0);
  signal   a1_i        : SLVArray(3 downto 0)(W - 1 downto 0);

begin

  ODDEVEN_4_1 : entity work.oddeven__4
    generic map (
      W     => W,
      DEPTH => DEPTH,
      N     => N
    )
    port map (
      CLK    => clk,
      E_I    => e_i,
      RST_I  => rst_i,
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

    e_i   <= '0';
    wait for CKTIME / 2;
    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';
    e_i   <= '1';
    wait for (W) * CKTIME;
    a0_i  <= (X"42", X"F1", X"A1", X"F2");

    wait for 2 * CKTIME;

    for i in 0 to 3 loop

      assert a1_i(i) = A_SORTED_I(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " a1_i(i)=   " & integer'image(to_integer(unsigned(a1_i(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(A_SORTED_I(i)))) &
               " Expectation  a1_i(i) = A_Sorted_i(i)";

    end loop;

    wait for CKTIME;
    A_SORTED_I <= (X"F2", X"F1", X"A1", X"42");

    wait for W * CKTIME;

    for i in 0 to 3 loop

      assert a1_i(i) = A_SORTED_I(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(b(i)))) &
               " A_Sorted_i(i)= " & integer'image(to_integer(unsigned(a_sorted(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture BEHAVIORAL;
