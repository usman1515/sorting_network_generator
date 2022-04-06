-----------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_Validator - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library work;
use work.CustomTypes.all;

entity Sim_Validator is
--  Port ( );
end Sim_Validator;

architecture Behavioral of Sim_Validator is

  constant ckTime : time := 10 ns;
  constant W : integer := 8;
  constant N : integer := 16;

  signal CLK   : std_logic;
  signal R : std_logic;

  component Validator is
    generic (
      W : integer;
      N : integer);
    port (
      CLK   : in  std_logic;
      R     : in  std_logic;
      E     : in  std_logic;
      input : in  SLVArray(N-1 downto 0)(W-1 downto 0);
      valid : out std_logic);
  end component Validator;

  signal valid : std_logic := '1';
  signal A : SLVArray(N-1 downto 0)(W-1 downto 0) := (others => (others => '0'));

begin

  CLK_process : process
  begin
    CLK <= '0';
    wait for ckTime/2;
    CLK <= '1';
    wait for ckTime/2;
  end process;

  Validator_1: entity work.Validator
    generic map (
      W => W,
      N => N)
    port map (
      CLK   => CLK,
      R     => R,
      E     => not R,
      input => A,
      valid => valid);

  test_process : process
  begin
    wait for ckTime/2;
    R <= '1';
    wait for ckTime;
    R <= '0';

    -- A is not in order,
    A <= (X"05", X"06", X"15", X"22",
          X"40", X"38", X"40", X"78",
          X"85", X"96", X"A5", X"B2",
          X"C8", X"D0", X"D0", X"F8");
    wait for ckTime;
    assert valid = '0' report "Mismatch:: " &
      " Expectation  valid = '0'";

    R <= '1';
    wait for ckTime;
    R <= '0';

    -- A is in order,
    A <= (X"05", X"06", X"15", X"22",
          X"38", X"40", X"40", X"78",
          X"85", X"96", X"A5", X"B2",
          X"C8", X"D0", X"D0", X"F8");
    wait for ckTime;
    assert valid = '1' report "Mismatch:: " &
      " Expectation  valid = '1'";

    wait;
  end process;

end Behavioral;
