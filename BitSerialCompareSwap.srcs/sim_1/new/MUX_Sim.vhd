----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name: 
-- Module Name: MUX_Sim - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MUX_Sim is
--  Port ( );
end MUX_Sim;

architecture Behavioral of MUX_Sim is

  constant ckTime : time := 10 ns;

  signal clock   : std_logic;
  signal input   : std_logic_vector(1 downto 0) := "00";
  signal sel_s   : std_logic                    := '0';
  signal output0 : std_logic_vector(1 downto 0);
  signal output1 : std_logic_vector(1 downto 0);
  component MUX
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      c   : out std_logic;
      d   : out std_logic
      );
  end component;

  component MUX_PRIMITIVE
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      CLK : in std_logic;
      c   : out std_logic;
      d   : out std_logic
      );
  end component;
begin

  clock_process : process
  begin
    clock <= '0';
    wait for ckTime/2;
    clock <= '1';
    wait for ckTime/2;
  end process;

  uut_0 : MUX
    port map(input(0), input(1), sel_s, output0(0), output0(1));

  uut_1 : MUX_PRIMITIVE
    port map(input(0), input(1), sel_s, clock, output1(0), output1(1));


  test_process : process
  begin
    wait for 10 * ckTime;
    input <= "00";
    sel_s <= '0';
    wait for ckTime;
    input <= "01";
    sel_s <= '0';
    wait for ckTime;
    input <= "10";
    sel_s <= '0';
    wait for ckTime;
    input <= "11";
    sel_s <= '0';
    wait for ckTime;
    input <= "00";
    sel_s <= '1';
    wait for ckTime;
    input <= "01";
    sel_s <= '1';
    wait for ckTime;
    input <= "10";
    sel_s <= '1';
    wait for ckTime;
    input <= "11";
    sel_s <= '1';
    wait;

  end process;

end Behavioral;
