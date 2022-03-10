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

entity BitCS is
  port (
    a     : in  std_logic;
    b     : in  std_logic;
    c     : out std_logic;
    d     : out std_logic;
    CLK   : in  std_logic;
    start : in  std_logic);
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

  StateMachine : process(CLK, start)
  begin
    if(CLK'event and CLK = '1') then
      if start = '1' then
        state <= "00";
      else
        case state is
          when "00" =>
            if a = '1' and b = '0' then
              state <= "01";
            elsif a = '0' and b = '1' then
              state <= "10";
            else
              state <= "00";
            end if;
          when "01" =>
            state <= "01";
          when "10" =>
            state <= "10";
          when "11" => 
            state <= "00";
        end case;
      end if;
    end if;
  end process;

  outMUX : MUX
    port map(a, b, state(1), c, d);


end Behavioral;
