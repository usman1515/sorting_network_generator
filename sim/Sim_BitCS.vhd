----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_BitCS - Behavioral
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

entity Sim_BitCS is
--  Port ( );
end Sim_BitCS;

architecture Behavioral of Sim_BitCS is

  constant ckTime : time := 10 ns;

  signal clock : std_logic;
  signal a     : std_logic := '0';
  signal b     : std_logic := '0';
  signal c     : std_logic := '0';
  signal d     : std_logic := '0';
  signal S : std_logic := '0';

  signal Av : std_logic_vector(7 downto 0):= (others => '0');
  signal Bv : std_logic_vector(7 downto 0):= (others => '0');
  signal Cv : std_logic_vector(7 downto 0) := (others => '0');
  signal Dv : std_logic_vector(7 downto 0) := (others => '0');

  component BitCS is
    port (
      a     : in  std_logic;
      b     : in  std_logic;
      c     : out std_logic;
      d     : out std_logic;
      S : in  std_logic);
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
    port map( a, b, c, d, S);


  test_process : process

  begin
    wait for 5*ckTime;
    -- State transitions with S enabled.
    S <= '1';
    for i in std_logic range '0' to '1' loop
      for j in std_logic range '0' to '1' loop
        a <= i;
        b <= j;
        wait for ckTime;
      end loop;
    end loop;
    for i in std_logic range '0' to '1' loop
      for j in std_logic range '0' to '1' loop
        a <= j;
        b <= i;
        wait for ckTime;
      end loop;
    end loop;

-- Functional check:
-- Av is first equal then larger, then equal and then smaller than Bv.
    S <= '1';
    Av    <= "10110110";
    Bv    <= "10100111";
    wait for ckTime;
    for i in Av'low to Av'high loop
      a <= Av(Av'high - i);
      b <= Bv(Bv'high - i);

      wait for ckTime/2;
      Cv(Cv'high - i) <= c;
      Dv(DV'high - i) <= d;
      S           <= '0';
      wait for ckTime/2;
      
    end loop;
    assert ((Av = Cv) and (Bv = Dv)) report "Mismatch:: " &
      " Av= " & integer'image(to_integer(unsigned(Av))) &
      " Bv= " & integer'image(to_integer(unsigned(Bv))) &
      " Cv= " & integer'image(to_integer(unsigned(Cv))) &
      " Dv= " & integer'image(to_integer(unsigned(Dv))) &
      " Expectation Av=Cv and Bv=Cv";

-- Av is first equal then larger, then equal and then smaller than Bv.
    S <= '1';
    Av    <= "10100111";
    Bv    <= "10110110";
    wait for ckTime;
    for i in Av'low to Av'high loop
      a <= Av(Av'high - i);
      b <= Bv(Bv'high - i);

      wait for ckTime/2;
      Cv(Cv'high - i) <= c;
      Dv(DV'high - i) <= d;
      S           <= '0';
      wait for ckTime/2;

    end loop;
    assert ((Av = Cv) and (Bv = Dv)) report "Mismatch:: " &
      " Av= " & integer'image(to_integer(unsigned(Av))) &
      " Bv= " & integer'image(to_integer(unsigned(Bv))) &
      " Cv= " & integer'image(to_integer(unsigned(Cv))) &
      " Dv= " & integer'image(to_integer(unsigned(Dv))) &
      " Expectation Av=Cv and Bv=Cv";

    wait;

  end process;

end Behavioral;
