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
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity BitCS is
  port (
    a : in  std_logic;
    b : in  std_logic;
    c : out std_logic;
    d : out std_logic;
    S : in  std_logic);
end BitCS;


architecture Behavioral of BitCS is

  component MUX is
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      c   : out std_logic;
      d   : out std_logic);
  end component MUX;

  signal state : std_logic_vector(1 downto 0) := "00";

begin

  process(a, b, S, state)
  begin
    case state is
      when "00" =>
        if a = '1' and b = '0' then
          state <= "01";
        elsif a = '0' and b = '1' then
          state <= "10";
        end if;
      when "01" =>
        if S = '1' then
          if a = '1' and b = '0' then
            state <= "01";
          elsif a = '0' and b = '1' then
            state <= "10";
          else
            state <= "00";
          end if;
        else
          state <= "01";
        end if;
      when "10" =>
        if S = '1' then
          if a = '1' and b = '0' then
            state <= "01";
          elsif a = '0' and b = '1' then
            state <= "10";
          else
            state <= "00";
          end if;
        else
          state <= "10";
        end if;
      when others =>
        state <= "00";
    end case;
  end process;

  outMUX : MUX
    port map(a, b, state(1), c, d);


end Behavioral;
