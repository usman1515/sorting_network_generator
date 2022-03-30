----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_BitCS_Sync - Behavioral
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

entity Sim_BitCS_Sync is
--  Port ( );
end Sim_BitCS_Sync;

architecture Behavioral of Sim_BitCS_Sync is

  constant ckTime : time := 10 ns;

  signal CLK   : std_logic;
  signal a     : std_logic := '0';
  signal b     : std_logic := '0';
  signal c     : std_logic := '0';
  signal d     : std_logic := '0';
  signal S     : std_logic := '0';

  signal Av : std_logic_vector(7 downto 0):= (others => '0');
  signal Bv : std_logic_vector(7 downto 0):= (others => '0');
  signal Cv : std_logic_vector(7 downto 0) := (others => '0');
  signal Dv : std_logic_vector(7 downto 0) := (others => '0');

  component BitCS_Sync is
    port (
      CLK   : in std_logic;
      a     : in  std_logic;
      b     : in  std_logic;
      c     : out std_logic;
      d     : out std_logic;
      S     : in  std_logic);
  end component BitCS_Sync;

begin

  CLK_process : process
  begin
    CLK <= '0';
    wait for ckTime/2;
    CLK <= '1';
    wait for ckTime/2;
  end process;


  BitCS_Sync_1: BitCS_Sync
    port map (
      CLK => CLK,
      a   => a,
      b   => b,
      c   => c,
      d   => d,
      S   => S);

  test_process : process

  begin
    wait for ckTime/2;
    -- State transitions with S enabled.
    -- S <= '1';
    -- for i in std_logic range '0' to '1' loop
    --   for j in std_logic range '0' to '1' loop
    --     a <= i;
    --     b <= j;
    --     wait for ckTime;
    --   end loop;
    -- end loop;
    -- S <= '0';
    -- for i in std_logic range '0' to '1' loop
    --   for j in std_logic range '0' to '1' loop
    --     a <= j;
    --     b <= i;
    --     wait for ckTime;
    --   end loop;
    -- end loop;

-- Functional check:
-- Av is first equal then larger, then equal and then smaller than Bv.
    Av    <= "01010101";
    Bv    <= "10101010";
    wait for ckTime;
    
    S <= '1';
    a <= Av(Av'high);
    b <= Bv(Bv'high);
    wait for ckTime;
    
    S           <= '0';
    
    for i in Av'low to Av'high-1 loop 
      a <= Av(Av'high-i -1);
      b <= Bv(Bv'high-i -1);
      wait for ckTime;
      
      Cv(Cv'high - i) <= c;
      Dv(DV'high - i) <= d;  
    end loop;
    
    wait for ckTime;
    Cv(0) <= c;
    Dv(0) <= d;
    
    
    assert ((Av = Dv) and (Bv = Cv)) report "Mismatch:: " &
      " Av= " & integer'image(to_integer(unsigned(Av))) &
      " Bv= " & integer'image(to_integer(unsigned(Bv))) &
      " Cv= " & integer'image(to_integer(unsigned(Cv))) &
      " Dv= " & integer'image(to_integer(unsigned(Dv))) &
      " Expectation Av=Dv and Bv=Cv";

-- Av is first equal then larger, then equal and then smaller than Bv.
    -- S <= '1';
    -- Av    <= X"A1";
    -- Bv    <= X"F2";
    -- wait for ckTime;
    -- for i in Av'low to Av'high loop
    --   a <= Av(Av'high - i);
    --   b <= Bv(Bv'high - i);

    --   wait for ckTime/2;
    --   Cv(Cv'high - i) <= c;
    --   Dv(DV'high - i) <= d;
    --   S           <= '0';
    --   wait for ckTime/2;

    -- end loop;
    -- assert ((Av = Dv) and (Bv = Cv)) report "Mismatch:: " &
    --   " Av= " & integer'image(to_integer(unsigned(Av))) &
    --   " Bv= " & integer'image(to_integer(unsigned(Bv))) &
    --   " Cv= " & integer'image(to_integer(unsigned(Cv))) &
    --   " Dv= " & integer'image(to_integer(unsigned(Dv))) &
    --   " Expectation Av=Dv and Bv=Cv";

    wait;

  end process;

end Behavioral;
