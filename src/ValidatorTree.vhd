-- Engineer:
-- Create Date:
-- Design Name:
-- Module Name: ValidatorTree - Behavioral
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

entity ValidatorTree is
generic(
  W : integer := 8;
  N : integer := 16
);
port(
    CLK : in std_logic;
    E : in std_logic;
    R : in std_logic;
    input_max : in SLVArray(N/W-1 downto 0)(W-1 downto 0);
    input_min : in SLVArray(N/W-1 downto 0)(W-1 downto 0);
    valid_in  : in std_logic_vector(N/W-1 downto 0);
    valid_out : out std_logic
);
end ValidatorTree;

architecture Behavioral of ValidatorTree is
  constant M : integer := N/W;
  constant Depth : integer := 3;
begin

  process
  begin
    wait until rising_edge(CLK);
    if R = '1' then
      valid_out <= '1';
    elsif E = '1' then
      for i in 0 to N/W -2 loop
        if not( input_max(0) <= input_min(1)) then
          valid_out <= '0';
        end if;
      end loop;
      for i in 0 to N/W - 1 loop
        if valid_in(i) = '0' then
          valid_out <= '0';
        end if;
      end loop;
    end if;
  end process;


end Behavioral;
