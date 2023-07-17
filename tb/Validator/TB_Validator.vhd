----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_Validator- Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the Validator component.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity TB_VALIDATOR is
--  Port ( );
end entity TB_VALIDATOR;

architecture TB of TB_VALIDATOR is

  constant CLK_PERIOD : time    := 10 ns;
  constant M          : integer := 16;
  constant W          : integer := 8;
  constant SW         : integer := 1;

  signal clk_i : std_logic;
  signal rst_i : std_logic;

  signal data_i         : SLVArray(0 to M-1)(W -1 downto 0);
  signal data_valid_i   : std_logic;
  signal data_ready_o   : std_logic;
  signal in_order_o     : std_logic;
  signal all_in_order_o : std_logic;

begin

  CLK_PROCESS : process is
  begin

    clk_i <= '0';
    wait for CLK_PERIOD / 2;
    clk_i <= '1';
    wait for CLK_PERIOD / 2;

  end process CLK_PROCESS;

  VALIDATOR_1 : entity work.VALIDATOR
    generic map (
      M  => M,
      W  => W,
      SW => SW)
    port map (
      CLK_I          => clk_i,
      RST_I          => rst_I,
      data_I         => data_i,
      DATA_VALID_I   => data_valid_i,
      DATA_READY_O   => data_ready_o,
      IN_ORDER_O     => in_order_o,
      ALL_IN_ORDER_O => all_in_order_o
      );

  test_PROCESS : process is
  begin
    rst_i        <= '1';
    data_valid_i <= '0';
    wait for CLK_PERIOD;
    rst_i        <= '0';
    assert data_ready_o = '1'
      report "Mismatch:: " &
      " Expectation data_ready_o = '1'";

    -- A is not in order,
    data_i <= (X"05", X"06", X"15", X"22",
               X"40", X"38", X"40", X"78",
               X"85", X"96", X"A5", X"B2",
               X"C8", X"D0", X"D0", X"F8");
    data_valid_i <= '1';
    wait for CLK_PERIOD;

    assert data_ready_o = '0'
      report "Mismatch:: " &
      " Expectation data_ready_o = '0'";
    data_valid_i <= '1';

    wait for (W/SW -1)*CLK_PERIOD;
    assert in_order_o = '0'
      report "Mismatch:: " &
      " Expectation  in_order_o = '0'";

    rst_i        <= '1';
    data_valid_i <= '0';
    wait for CLK_PERIOD;
    rst_i        <= '0';

    assert data_ready_o = '1'
      report "Mismatch:: " &
      " Expectation data_ready_o = '1'";
    -- data_i is in order,
    data_i <= (X"05", X"06", X"15", X"22",
               X"38", X"40", X"40", X"78",
               X"85", X"96", X"A5", X"B2",
               X"C8", X"D0", X"D0", X"F8");
    data_valid_i <= '1';
    wait for CLK_PERIOD;
    assert in_order_o = '1'
      report "Mismatch:: " &
      " Expectation  in_order_o = '1'";

    wait;

  end process TEST_PROCESS;

end architecture TB;
