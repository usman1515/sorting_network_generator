---------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_RRDMUX_NxW - Behavioral
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


entity Sim_LFSR_RRDMUX_RRMUX is
--  Port ( );
end Sim_LFSR_RRDMUX_RRMUX;

architecture Behavioral of Sim_LFSR_RRDMUX_RRMUX is


  component LFSR is
    generic (
      W : integer;
      P : std_logic_vector);
    port (
      CLK    : in  std_logic;
      E      : in  std_logic;
      R      : in  std_logic;
      seed   : in  std_logic_vector(W-1 downto 0);
      output : out std_logic_vector(W-1 downto 0));
  end component LFSR;

  component RRDMUX_NxW is
    generic (
      W : integer;
      N : integer);
    port (
      CLK    : in  std_logic;
      E      : in  std_logic;
      R      : in  std_logic;
      input  : in  std_logic_vector(W-1 downto 0);
      output : out SLVArray(N-1 downto 0)(W-1 downto 0));
  end component RRDMUX_NxW;

  component RRMUX_NxW is
    generic (
      W : integer;
      N : integer);
    port (
      CLK    : in  std_logic;
      E      : in  std_logic;
      R      : in  std_logic;
      input  : in  SLVArray(N-1 downto 0)(W-1 downto 0);
      output : out std_logic_vector(W-1 downto 0));
  end component RRMUX_NxW;

  constant ckTime : time := 10 ns;
  constant W : integer := 8;
  constant N : integer := 8;
  constant P : std_logic_vector(W-1 downto 0) := "10111000";
  constant seed : std_logic_vector(W-1 downto 0) := X"5A";

  signal CLK   : std_logic;
  signal R : std_logic;
  signal E :std_logic;
  signal input: std_logic_vector(W-1 downto 0) := (others => '0');
  signal inter : SLVArray(N-1 downto 0)(W-1 downto 0) := (others => (others => '0'));
  signal output: std_logic_vector(W-1 downto 0) := (others => '0');

begin

  CLK_process : process
  begin
    CLK <= '0';
    wait for ckTime/2;
    CLK <= '1';
    wait for ckTime/2;
  end process;

  LSFR_1: LFSR
    generic map (
      W => W,
      P => P)
    port map (
      CLK    => CLK,
      E      => E,
      R      => R,
      seed   => seed,
      output => input);

  RRDMUX_NxW_1: entity work.RRDMUX_NxW
    generic map (
      W => W,
      N => N)
    port map (
      CLK    => CLK,
      E      => E,
      R      => R,
      input  => input,
      output => inter);

  RRMUX_NxW_1: entity work.RRMUX_NxW
    generic map (
      W => W,
      N => N)
    port map (
      CLK    => CLK,
      E      => E,
      R      => R,
      input  => inter,
      output => output);

  test_process : process
  begin
    wait for ckTime/2;
    R <= '1';
    E <= '0';
    wait for ckTime/2;
    E <= '1';
    R <= '0';
    wait for 16*ckTime/2;

    wait;

  end process;

end Behavioral;
