----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SIM_BITCS_CONTROLLOGIC - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for asynchronous Bitserial Compare Swap component
-- with I/O shift registers and CYLCLE_TIMER for control signal generation.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity SIM_BITCS_CONTROLLOGIC is
  generic (
    W : integer := 8
  );
end entity SIM_BITCS_CONTROLLOGIC;

architecture BEHAVIORAL of SIM_BITCS_CONTROLLOGIC is

  constant CKTIME                 : time := 10 ns;

  signal clk                      : std_logic;

  signal a0_i                     : std_logic;
  signal b0_i                     : std_logic;
  signal a1_i                     : std_logic;
  signal b1_i                     : std_logic;

  signal start_i                  : std_logic;

  signal e_i                      : std_logic;
  signal rst                      : std_logic;

  signal value_0_i                : std_logic_vector(W - 1 downto 0) ;
  signal value_1_i                : std_logic_vector(W - 1 downto 0) ;
  signal output_0_i               : std_logic_vector(W - 1 downto 0) ;
  signal output_1_i               : std_logic_vector(W - 1 downto 0) ;

  signal larger_value             : std_logic_vector(W - 1 downto 0) ;
  signal smaller_value            : std_logic_vector(W - 1 downto 0) ;

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  UUT_0 : BITCS
    port map (
      A0    => a0_i,
      B0    => b0_i,
      A1    => a1_i,
      B1    => b1_i,
      START => start_i
    );

  CYCLE_TIMER_1 : entity work.CYCLE_TIMER
    generic map (
      W => W
    )
    port map (
      CLK     => clk,
      RST     => rst,
      E     => e_i,
      START => start_i
    );

  LOAD_SHIFT_REGISTER_1 : entity work.LOAD_SHIFT_REGISTER
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E        => e_i,
      LOAD         => start_i,
      PAR_INPUT      => value_0_i,
      SER_OUTPUT => a0
    );

  LOAD_SHIFT_REGISTER_2 : LOAD_SHIFT_REGISTER
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E_I        => e_i,
      LD         => start_i,
      INPUT      => value_1_i,
      SER_OUTPUT => b0
    );

  STORE_SHIFT_REGISTER_1 : STORE_SHIFT_REGISTER
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E_I        => e,
      ST         => start_i,
      SER_INPUT  => a1,
      PAR_OUTPUT => output_0_i
    );

  STORE_SHIFT_REGISTER_2 : STORE_SHIFT_REGISTER
    generic map (
      W => W
    )
    port map (
      E          => e,
      CLK        => clk,
      ST         => start_i,
      SER_INPUT  => b1,
      PAR_OUTPUT => output_1_i
    );

  TEST_PROCESS : process is

  begin

    larger_value  <= "10110110";
    smaller_value <= "10100111";
    e_i           <= '0';
    wait for CKTIME / 2;
    rst           <= '1';
    value_0_i     <= larger_value;
    value_1_i     <= smaller_value;
    wait for CKTIME;
    rst           <= '0';
    e_i           <= '1';
    wait for (W - 1) * CKTIME;

    value_0_i <= smaller_value;
    value_1_i <= larger_value;
    wait for 3 * CKTIME;
    assert ((larger_value = output_0_i) and (smaller_value = output_1_i))
      report "Mismatch:: " &
             " value_0_i= " & integer'image(to_integer(unsigned(larger_value))) &
             " value_1_i= " & integer'image(to_integer(unsigned(smaller_value))) &
             " output_0_i= " & integer'image(to_integer(unsigned(output_0_i))) &
             " D= " & integer'image(to_integer(unsigned(output_1_i))) &
             " Expectation value_0_i=output_0_i and value_1_i=output_1_i";

    wait for (W - 4) * CKTIME;
    assert ((larger_value = output_0_i) and (smaller_value = output_1_i))
      report "Mismatch:: " &
             " value_0_i= " & integer'image(to_integer(unsigned(smaller_value))) &
             " value_1_i= " & integer'image(to_integer(unsigned(larger_value))) &
             " output_0_i= " & integer'image(to_integer(unsigned(output_0_i))) &
             " output_1_i= " & integer'image(to_integer(unsigned(output_1_i))) &
             " Expectation value_0_i=output_1_i and value_1_i=output_0_i";
    wait;

  end process TEST_PROCESS;

end architecture BEHAVIORAL;
