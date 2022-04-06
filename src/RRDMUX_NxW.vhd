------------------
-- Company:
-- Engineer:
--
-- Create Date:
-- -- Design Name:
-- Module Name: RRDMUX_NxW - Behavioral
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

library work;
use work.CustomTypes.all;

entity RRDMUX_NxW is
generic(
  W : integer := 8;
  N : integer := 8
);
port(
    CLK : in std_logic;
    E : in std_logic;
    R : in std_logic;
    input : in std_logic_vector(W-1 downto 0);
    output : out SLVArray(N-1 downto 0)(W-1 downto 0)
);
end RRDMUX_NxW;

architecture Behavioral of RRDMUX_NxW is
  signal count : integer range 0 to N-1 := 0;
begin

    Counter : process
    begin
    wait until rising_edge(CLK);
        if R = '1' or count = N-1 then
            count <= 0;
        else
          if E = '1' then
            count <= count + 1;
          end if;
        end if;
    end process;

    DEMUX : process
    begin
      wait until rising_edge(CLK);
      if R = '1' then
        output <= (others => (others => '0'));
      else
        output(count) <= input;
      end if;
    end process;

end Behavioral;
