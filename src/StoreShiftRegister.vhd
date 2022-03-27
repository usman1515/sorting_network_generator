----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LoadShiftRegister - Behavioral
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
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity StoreShiftRegister is
  generic(
    W : integer := 8
    );
  port (

    CLK       : in  std_logic;
    E         : in  std_logic;
    ser_input : in  std_logic;
    ST        : in  std_logic;
    output    : out std_logic_vector(W-1 downto 0) := (others => '0')
    );
end StoreShiftRegister;


architecture Behavioral of StoreShiftRegister is

  signal buf : std_logic_vector(W-1 downto 0) := (others => '0');
begin
  process
  begin
    wait until rising_edge(CLK);
    if E = '1' then
      buf <= buf(buf'high-1 downto buf'low) & ser_input;
    end if;
    if ST = '1' then
      output <= buf;
    end if;
  end process;

end Behavioral;
