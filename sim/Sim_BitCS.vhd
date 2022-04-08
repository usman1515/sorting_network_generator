----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SIM_BITCS - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for asynchronous Bitserial Compare Swap component.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity SIM_BITCS is
  --  Port ( );
end entity SIM_BITCS;

architecture BEHAVIORAL of SIM_BITCS is

  constant CKTIME           : time := 10 ns;

  signal clock              : std_logic;
  signal a0_i               : std_logic;
  signal b0_i               : std_logic;
  signal a1_i               : std_logic;
  signal b1_i               : std_logic;
  signal start_i            : std_logic;

  signal a_vec_i            : std_logic_vector(7 downto 0);
  signal b_vec_i            : std_logic_vector(7 downto 0);
  signal a_vec_res_i        : std_logic_vector(7 downto 0);
  signal b_vec_res_i        : std_logic_vector(7 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clock <= '0';
    wait for CKTIME / 2;
    clock <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  BITCS_1 : entity work.bitcs
    port map (
      A0    => a0_i,
      B0    => b0_i,
      A1    => a1_i,
      B1    => b1_i,
      START => start_i
    );

  TEST_PROCESS : process is

  begin

    wait for 5 * CKTIME;
    -- State transitions with S enabled.
    start_i <= '1';

    for i in std_logic range '0' to '1' loop

      for j in std_logic range '0' to '1' loop

        a0_i <= i;
        b0_i <= j;
        wait for CKTIME;

      end loop;

    end loop;

    for i in std_logic range '0' to '1' loop

      for j in std_logic range '0' to '1' loop

        a0_i <= j;
        b0_i <= i;
        wait for CKTIME;

      end loop;

    end loop;

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    start_i <= '1';
    a_vec_i <= "10110110";
    b_vec_i <= "10100111";
    wait for CKTIME;

    for i in a'low to a'high loop

      a0_i <= a_vec_i(a_vec_i'high - i);
      b0_i <= b_vec_i(b_vec_i'high - i);

      wait for CKTIME / 2;
      a_vec_res_i(a_vec_res_i'high - i) <= a1_i;
      b_vec_res_i(b_vec_res_i'high - i) <= b1_i;
      start_i                           <= '0';
      wait for CKTIME / 2;

    end loop;

    assert ((a_vec_i = a_vec_res_i) and (b_vec_i = b_vec_res_i))
      report "Mismatch:: " &
             " A_vec_i= " & integer'image(to_integer(unsigned(a_vec_i))) &
             " B_vec_i= " & integer'image(to_integer(unsigned(b_vec_i))) &
             " A_vec_res_i " & integer'image(to_integer(unsigned(a_vec_res_i))) &
             " B_vec_res_i= " & integer'image(to_integer(unsigned(b_vec_res_i))) &
             " Expectation A_vec_i=A_vec_res_i and B_vec_i=B_vec_res_i";

    -- Av is first equal then larger, then equal and then smaller than Bv.
    start_i <= '1';
    a_vec_i <= "10100111";
    b_vec_i <= "10110110";
    wait for CKTIME;

    for i in a_vec_i'low to a_vec_i'high loop

      a0_i <= a_vec_i(a_vec_i'high - i);
      b0_o <= b_vec_i(b_vec_i'high - i);

      wait for CKTIME / 2;
      a_vec_res_i(a_vec_res_i'high - i) <= a1_i;
      b_vec_res_i(b_vec_res_i'high - i) <= b1_i;
      start_i                           <= '0';
      wait for CKTIME / 2;

    end loop;

    assert ((a_vec_i = a_vec_res_i) and (b_vec_i = b_vec_res_i))
      report "Mismatch:: " &
             " A_vec_i= " & integer'image(to_integer(unsigned(a_vec_i))) &
             " B_vec_i= " & integer'image(to_integer(unsigned(b_vec_i))) &
             " A_vec_res_i " & integer'image(to_integer(unsigned(a_vec_res_i))) &
             " B_vec_res_i= " & integer'image(to_integer(unsigned(b_vec_res_i))) &
             " Expectation A_vec_i=A_vec_res_i and B_vec_i=B_vec_res_i";

    wait;

  end process TEST_PROCESS;

end architecture BEHAVIORAL;
