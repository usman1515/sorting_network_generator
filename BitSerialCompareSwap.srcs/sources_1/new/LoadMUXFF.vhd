----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LoadMUXFF - Behavioral
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

entity LoadMUXFF is
  generic(
    w : integer := 8
    );
  port (

    CLK        : in  std_logic;
    LD         : in  std_logic;
    E          : in  std_logic;
    input      : in  std_logic_vector(w-1 downto 0);
    ser_output : out std_logic := '0'
    );
end LoadMUXFF;


architecture Behavioral of LoadMUXFF is
-- We can make do with one bit less as the first input bit
-- is immediatly output with ser_output.
  signal buf : std_logic_vector(w-1 downto 0) := (others => '0');
  signal count: integer range 0 to w-1;
begin

  process
  begin
    wait until rising_edge(CLK);
    if LD = '1' or count = w-1 then
      count <= 0;
    else
      if E = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;

  process
  begin
    wait until rising_edge(CLK);
    if LD = '1' then
      buf <= input(input'high downto input'low);
    end if;
  end process;

  process(LD, buf, input)
  begin
    if LD = '1' then
      ser_output <= input(0);
    else
      ser_output <= buf(count);
    end if;
  end process;


end Behavioral;
