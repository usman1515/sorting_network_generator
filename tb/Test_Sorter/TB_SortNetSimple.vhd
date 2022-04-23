----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_SortNetSimple - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the SortNetSimple component.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_SORTNETSIMPLE is
end entity TB_SORTNETSIMPLE;

architecture TB of TB_SORTNETSIMPLE is

  constant W            : integer := 8;
  constant DEPTH        : integer := 3;
  constant N            : integer := 4;

  constant CKTIME       : time := 10 ns;
  signal   clk          : std_logic;

  signal rst_i          : std_logic;
  signal e_i            : std_logic;

  signal a0_sorted_i    : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal a0_i           : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal a1_i           : SLVArray(0 to N - 1)(W - 1 downto 0);

begin

  SORTNETSIMPLE_1 : entity work.sortnetsimple
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => b0_i
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

    a0_sorted_i <= (X"F2", X"A8", X"5C", X"2B");
    e_i         <= '0';
    wait for CKTIME / 2;
    rst_i       <= '1';
    wait for CKTIME;
    rst_i       <= '0';
    e_i         <= '1';
    wait for (W) * CKTIME;
    a0_i        <= (X"42", X"F1", X"A1", X"F2");
    -- A0_i <= (others => (others => '0'));
    wait for 2 * CKTIME;

    for i in 0 to 3 loop

      assert a1_i(i) = a0_sorted_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(B(i)))) &
               " A_Sorted(i)= " & integer'image(to_integer(unsigned(A_Sorted(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    wait for CKTIME;
    a0_sorted_i <= (X"F2", X"F1", X"A1", X"42");

    wait for W * CKTIME;

    for i in 0 to 3 loop

      assert B(i) = A_Sorted(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(B(i)))) &
               " A_Sorted(i)= " & integer'image(to_integer(unsigned(A_Sorted(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture TB;
