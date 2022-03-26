----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: BitCS - Behavioral
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

entity MUX is
    port (
        a   : in std_logic;
        b   : in std_logic;
        sel : in std_logic;

        c : out std_logic;
        d : out std_logic);
end MUX;

architecture Behavioral of MUX is
begin

    process(a,b,sel)
    begin  -- process
        if sel = '1' then
            c <= b;
            d <= a;
        else
            c <= a;
            d <= b;
        end if;
    end process;

end architecture Behavioral;
