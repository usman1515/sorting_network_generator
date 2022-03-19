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

entity LoadShiftRegister is
  generic(
    w : integer := 8
    );
  port (

    CLK        : in  std_logic;
    input      : in  std_logic_vector(w-1 downto 0);
    LD         : in  std_logic;
    ser_output : out std_logic := '0'
    );
end LoadShiftRegister;


architecture Behavioral of LoadShiftRegister is
-- We can make do with one bit less as the first input bit 
-- is immediatly output with ser_output.
  signal buf : std_logic_vector(w-1 downto 0) := (others => '0');
begin
  process
  begin
    wait until rising_edge(CLK);
    if LD = '0' then
      buf <= buf(buf'high -1 downto buf'low) & '0';
    else
      buf <= input(input'high -1 downto input'low) & '0';
    end if;
  end process;

  process(LD, buf, input)
  begin
    if LD = '1' then
      ser_output <= input(input'high);
    else
      ser_output <= buf(buf'high);
    end if;
  end process;


end Behavioral;
