---------------------------------
-- Company:
-- Engineer:
--
-- Create Date:
-- -- Design Name:
-- Module Name: LSFRGalois - Behavioral
-- Project Name::
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

entity LSFR is
    generic(
      W : integer := 8;
      P : std_logic_vector(W-1 downto 0) := "10001101"
    );
    port(
      CLK : in std_logic;
      E : in std_logic;
      R : in std_logic;
      seed: in std_logic_vector(W-1 downto 0);
      output : out std_logic_vector(W-1 downto 0)
    );
end LSFR;

architecture Behavioral of LSFR is
  signal reg : std_logic_vector(W-1 downto 0):= (others=>'0');
  signal mask : std_logic_vector(W-1 downto 0):= (others=>'0');
begin

  mask(W-1 downto 0) <= P(W-1 downto 0) and reg(0);
  output <= reg;

  Main : process
  begin
    wait until rising_edge(CLK);
    if R = '1' then
      reg <= seed;
    else
      if E = '1' then
        reg <= '0'& reg(W-1 downto 1) xor mask;
      end if;
    end if;
  end process Main;

end Behavioral;
