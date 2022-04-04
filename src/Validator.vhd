-- Company:
-- Engineer:
--
-- Create Date:
-- -- Design Name:
-- Module Name: Validator - Behavioral
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

entity Validator is
generic(
  W : integer := 8
);
port(
    CLK : in std_logic;
    E : in std_logic;
    R : in std_logic;
    input : in std_logic_vector(W-1 downto 0);
    maxV : out std_logic_vector(W-1 downto 0);
    minV : out std_logic_vector(W-1 downto 0);
    valid : out std_logic
    );
end Validator;

architecture Behavioral of Validator is
  signal rmaxV : std_logic_vector(W-1 downto 0) := (others => '0');
  signal rminV : std_logic_vector(W-1 downto 0) := (others => '0');
begin

  maxV <= rmaxV;
  minV <= rminV;

  process
  begin
    wait until rising_edge(CLK);
    if R = '1' then
      rmaxV <= (others => '0');
      rminV <= (others => '1');
      valid <= '1';
    else
      if E = '1' then
        if unsigned(input) > unsigned(rmaxV) then
          rmaxV <= input;
        end if;
        if unsigned(input) < unsigned(rminV) then
          rminV <= input;
        end if;
        if unsigned(input) < unsigned(rmaxV) then
          valid <= '0';
        end if;
      end if;
    end if;
  end process;


end Behavioral;
