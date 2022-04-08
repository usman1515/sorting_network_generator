----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SIM_BITCS_Sync - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for synchronous Bitserial Compare Swap component.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

  -- Uncomment the following library declaration if using
  -- arithmetic functions with Signed or Unsigned values
  use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity SIM_BITCS_SYNC is
  --  Port ( );
end entity SIM_BITCS_SYNC;

architecture BEHAVIORAL of SIM_BITCS_SYNC is

  constant CKTIME    : time := 10 ns;

  signal clk         : std_logic;
  signal e_i         : std_logic;
  signal a0_i        : std_logic;
  signal b0_i        : std_logic;
  signal a1_i        : std_logic;
  signal b1_i        : std_logic;
  signal start_i     : std_logic;

  signal a_vec_i     : std_logic_vector(7 downto 0);
  signal b_vec_i     : std_logic_vector(7 downto 0);
  signal a_vec_res_i : std_logic_vector(7 downto 0);
  signal b_vec_res_i : std_logic_vector(7 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  BITCS_SYNC_1 : entity work.bitcs_sync
    port map (
      CLK   => clk,
      E     => e_i,
      A0    => a0_i,
      B0    => b0_i,
      A1    => a1_i,
      B1    => b1_i,
      START => start_i
    );

  TEST_PROCESS : process is

  begin

    wait for CKTIME / 2;
    -- State transitions with START_i enabled.
    -- START_i <= '1';
    -- for i in std_logic range '0' to '1' loop
    --   for j in std_logic range '0' to '1' loop
    --     a0_i <= i;
    --     b0_i <= j;
    --     wait for ckTime;
    --   end loop;
    -- end loop;
    -- START_i <= '0';
    -- for i in std_logic range '0' to '1' loop
    --   for j in std_logic range '0' to '1' loop
    --     a0_i <= j;
    --     b0_i <= i;
    --     wait for ckTime;
    --   end loop;
    -- end loop;

    -- Functional check:
    -- A_vec_i is first equal then larger, then equal and then smaller than B_vec_i.
    a_vec_i <= "01010101";
    b_vec_i <= "10101010";
    wait for CKTIME;

    start_i <= '1';
    a0_i    <= a_vec_i(a_vec_i'high);
    b0_i    <= b_vec_i(b_vec_i'high);
    wait for CKTIME;

    start_i <= '0';

    for i in a_vec_i'low to a_vec_i'high - 1 loop

      a0_i <= a_vec_i(a_vec_i'high - i - 1);
      b0_i <= b_vec_i(b_vec_i'high - i - 1);
      wait for CKTIME;

      a_vec_res_i(a_vec_res_i'high - i) <= a1_i;
      b_vec_res_i(b_vec_res_i'high - i) <= b1_i;

    end loop;

    wait for CKTIME;
    a_vec_res_i(0) <= a1_i;
    b_vec_res_i(0) <= b1_i;

    assert ((a_vec_i = b_vec_res_i) and (b_vec_i = a_vec_res_i))
      report "Mismatch:: " &
             " A_vec_i= " & integer'image(to_integer(unsigned(a_vec_i))) &
             " B_vec_i= " & integer'image(to_integer(unsigned(b_vec_i))) &
             " A_vec_res_i= " & integer'image(to_integer(unsigned(a_vec_res_i))) &
             " B_vec_res_i= " & integer'image(to_integer(unsigned(b_vec_res_i))) &
             " Expectation A_vec_i=B_vec_res_i and B_vec_i=A_vec_res_i";

    -- A_vec_i is first equal then larger, then equal and then smaller than B_vec_i.
    -- START_i <= '1';
    -- A_vec_i    <= X"A1";
    -- B_vec_i    <= X"F2";
    -- wait for ckTime;
    -- for i in A_vec_i'low to A_vec_i'high loop
    --   a0_i <= A_vec_i(A_vec_i'high - i);
    --   b0_i <= B_vec_i(B_vec_i'high - i);

    --   wait for ckTime/2;
    --   A_vec_res_i(A_vec_res_i'high - i) <= a1_i;
    --   B_vec_res_i(B_vec_res_i'high - i) <= b1_i;
    --   START_i           <= '0';
    --   wait for ckTime/2;

    -- end loop;
    -- assert ((A_vec_i = B_vec_res_i) and (B_vec_i = A_vec_res_i)) report "Mismatch:: " &
    --   " A_vec_i= " & integer'image(to_integer(unsigned(A_vec_i))) &
    --   " B_vec_i= " & integer'image(to_integer(unsigned(B_vec_i))) &
    --   " A_vec_res_i= " & integer'image(to_integer(unsigned(A_vec_res_i))) &
    --   " B_vec_res_i= " & integer'image(to_integer(unsigned(B_vec_res_i))) &
    --   " Expectation A_vec_i=B_vec_res_i and B_vec_i=A_vec_res_i";

    wait;

  end process TEST_PROCESS;

end architecture BEHAVIORAL;
