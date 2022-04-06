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
      W : integer);
    port (
      CLK : in std_logic;
      E : in std_logic;
      R : in std_logic;
      input : in std_logic_vector(W-1 downto 0);
      maxV : out std_logic_vector(W-1 downto 0);
      minV : out std_logic_vector(W-1 downto 0);
      valid : out std_logic);
  end component Validator;

  component ValidatorTree is
    generic (
      W : integer;
      N : integer);
    port (
      CLK       : in  std_logic;
      E         : in  std_logic;
      R         : in  std_logic;
      input_max : in  SLVArray(N/W-1 downto 0)(W-1 downto 0);
      input_min : in  SLVArray(N/W-1 downto 0)(W-1 downto 0);
      valid_in  : in std_logic_vector(N/W-1 downto 0);
      valid_out : out std_logic);
  end component ValidatorTree;

  signal local_max : SLVArray(N/W -1 downto 0 )(W-1 downto 0) := (others => (others => '0'));
  signal local_min : SLVArray(N/W -1 downto 0 )(W-1 downto 0):= (others => (others => '0'));
  signal local_valid : std_logic_vector(N/W -1 downto 0) := (others => '0');
  signal valid : std_logic := '1';
  signal A : std_logic_vector(W-1 downto 0) := (others => '0');
  signal B : std_logic_vector(W-1 downto 0) := (others => '0');
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
      W => W)
    port map (
      CLK       => CLK,
      E         => not R,
      R         => R,
      input     => A,
      maxV      => local_max(0),
      minV      => local_min(0),
      valid     => local_valid(0)
      );

  Validator_2: entity work.Validator
    generic map (
      W => W)
    port map (
      CLK       => CLK,
      E         => not R,
      R         => R,
      input     => B,
      maxV      => local_max(1),
      minV      => local_min(1),
      valid     => local_valid(1)
      );

  ValidatorTree_1: entity work.ValidatorTree
    generic map (
      W => W,
      N => N)
    port map (
      CLK       => CLK,
      E         => not R,
      R         => R,
      input_max => local_max,
      input_min => local_min,
      valid_in  => local_valid,
      valid_out => valid);

  test_process : process
  begin
    wait for ckTime/2;
    R <= '1';
    wait for ckTime;
    R <= '0';

    -- Max of sequence A eventually larger than min of B
    B <= X"25";
    A <= X"05";
    wait for ckTime;
    B <= X"28";
    A <= X"12";
    wait for ckTime;
    B <= X"47";
    A <= X"23";
    wait for ckTime;
    B <= X"C0";
    A <= X"28";
    wait for 2*ckTime;
    assert valid = '0' report "Mismatch:: " &
      " Expectation  valid = '0'";

    -- Sequence A > Sequence B
    R <= '1';
    wait for ckTime;
    R <= '0';
    B <= X"25";
    A <= X"05";
    wait for ckTime;
    B <= X"28";
    A <= X"12";
    wait for ckTime;
    B <= X"47";
    A <= X"23";
    wait for ckTime;
    B <= X"C0";
    A <= X"24";
    wait for 2*ckTime;
    assert valid = '1' report "Mismatch:: " &
      " Expectation  valid = '1'";


    -- Sequence A not internally ordered
    R <= '1';
    wait for ckTime;
    R <= '0';
    B <= X"25";
    A <= X"05";
    wait for ckTime;
    B <= X"28";
    A <= X"12";
    wait for ckTime;
    B <= X"47";
    A <= X"07";
    wait for ckTime;
    B <= X"C0";
    A <= X"06";
    wait for 2*ckTime;
    assert valid = '0' report "Mismatch:: " &
      " Expectation  valid = '0'";


    wait;
  end process;

end Behavioral;
