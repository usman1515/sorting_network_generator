----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: MUX_2X2 - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Asynchronous 2 to 2 MUX
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity MUX_2X2 is
  port (
    A0   : in    std_logic;
    B0   : in    std_logic;
    SEL  : in    std_logic;

    A1   : out   std_logic;
    B1   : out   std_logic
  );
end entity MUX_2X2;

architecture BEHAVIORAL of MUX_2X2 is

begin

  MUX : process (A0, B0, SEL) is
  begin

    if (SEL = '1') then
      A1 <= B0;
      B1 <= A0;
    else
      A1 <= A0;
      B1 <= B0;
    end if;

  end process MUX;

end architecture BEHAVIORAL;
