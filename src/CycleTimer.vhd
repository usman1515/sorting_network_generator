----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: CycleTimer - Behavioral
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

entity CycleTimer is
  generic (
    W : integer := 8                    -- Width of input bits
    );
  port (
    CLK : in  std_logic;
    R   : in  std_logic;                -- Synchronous reset
    E   : in  std_logic;  -- Enable signal, halts operation if unset
    LD  : out std_logic;                -- Operand load signal
    S   : out std_logic;                -- Sorting start signal
    ST  : out std_logic                 -- Result store signal
    );
end CycleTimer;


architecture Behavioral of CycleTimer is
  signal count : integer range 0 to w-1;
begin

  process
  begin
    wait until rising_edge(CLK);
    if R = '1' or count = w-1 then
      count <= 0;
    else
      if E = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;

  process(R, count)
  begin
    LD  <= '1' when count =1 and R ='0' else '0';
    S   <= '1' when count =1 and R ='0' else '0';
    ST  <= '1' when count =1 and R ='0' else '0';
  end process;

end Behavioral;
