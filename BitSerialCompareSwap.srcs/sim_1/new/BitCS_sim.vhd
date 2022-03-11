----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: BitCS_Sim - Behavioral
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

entity BitCS_Sim is
--  Port ( );
end BitCS_Sim;

architecture Behavioral of BitCS_Sim is

  constant ckTime : time := 10 ns;

  signal clock : std_logic;
  signal a     : std_logic := '0';
  signal b     : std_logic := '0';
  signal c     : std_logic := '0';
  signal d     : std_logic := '0';
  signal start : std_logic := '0';

  signal Av : std_logic_vector(7 downto 0);
  signal Bv : std_logic_vector(7 downto 0);
  signal Cv : std_logic_vector(7 downto 0) := (others => '0');
  signal Dv : std_logic_vector(7 downto 0) := (others => '0');

  component BitCS is
    port (
      a     : in  std_logic;
      b     : in  std_logic;
      c     : out std_logic;
      d     : out std_logic;
      start : in  std_logic);
  end component BitCS;

begin

  clock_process : process
  begin
    clock <= '0';
    wait for ckTime/2;
    clock <= '1';
    wait for ckTime/2;
  end process;


  uut_0 : BitCS
    port map(a, b, c, d, start);


  test_process : process

  begin
    
    
    Av    <= "10100100";
    Bv    <= "10100011";
    wait for 5*ckTime;
    start <= '1';
    for I in Av'low to Av'high loop
      
      a <= Av(Av'high - I);
      b <= Bv(Bv'high - I);
      wait for ckTime;
      Cv(Cv'high - I) <= c;
      Dv(DV'high - I) <= d;
      start <= '0';
    end loop;
    
    start <= '1';
    Av    <= "10100011";
    Bv    <= "10100100";
    for I in Av'low to Av'high loop
    
      a <= Av(Av'high - I);
      b <= Bv(Bv'high - I);
      wait for ckTime;
      Cv(Cv'high - I) <= c;
      Dv(DV'high - I) <= d;
      start <= '0';
    end loop;
    
    wait;

  end process;

end Behavioral;
