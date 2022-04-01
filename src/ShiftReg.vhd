---------------------------------
-- Company:
-- Engineer:
--
-- Create Date:
-- -- Design Name:
-- Module Name: ShiftRegister - Behavioral
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

entity ShiftRegister is
    generic(
      W : integer := 8
      );
    port(
      CLK : in std_logic;
      E : in std_logic;
      R : in std_logic;
      s_in: in std_logic;
      s_out : out std_logic
    );
end ShiftRegister;

architecture Behavioral of ShiftRegister is
  signal reg : std_logic_vector(W-1 downto 0):= (others=>'0');
begin

  Main : process
  begin
    wait until rising_edge(CLK);
    if R = '1' then
      reg <= (others => '0');
    else
      if E = '1' then
        reg <= reg(reg'high - 1 downto reg'low) & s_in;
      end if;
    end if;
    s_out <= reg(reg'high);
  end process Main;

end Behavioral;
