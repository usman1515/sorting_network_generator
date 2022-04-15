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

  constant CKTIME : time := 10 ns;
  constant W      : integer := 8;
  constant N      : integer := 16;

  signal clk      : std_logic;
  signal rst_i    : std_logic;

  signal valid_i  : std_logic;
  signal input_i  : SLVArray(N - 1 downto 0)(W - 1 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  VALIDATOR_1 : entity work.validator
    generic map (
      W => W,
      N => N
    )
    port map (
      CLK   => clk,
      RST   => rst_i,
      E     => not rst_i,
      INPUT => input_i,
      VALID => valid_i
    );

  TEST_PROCESS : process is
  begin

    wait for CKTIME / 2;
    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';

    -- A is not in order,
    input_i <= (X"05", X"06", X"15", X"22",
                X"40", X"38", X"40", X"78",
                X"85", X"96", X"A5", X"B2",
                X"C8", X"D0", X"D0", X"F8");
    wait for CKTIME;
    assert valid_i = '0'
      report "Mismatch:: " &
             " Expectation  valid_i = '0'";

    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';

    -- input_i is in order,
    input_i <= (X"05", X"06", X"15", X"22",
                X"38", X"40", X"40", X"78",
                X"85", X"96", X"A5", X"B2",
                X"C8", X"D0", X"D0", X"F8");
    wait for CKTIME;
    assert valid_i = '1'
      report "Mismatch:: " &
             " Expectation  valid_i = '1'";

    wait;

  end process TEST_PROCESS;

end architecture TB;
