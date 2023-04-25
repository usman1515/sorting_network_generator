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
    A_I   : in    std_logic;
    B_I   : in    std_logic;
    SEL_I  : in    std_logic;

    A_O   : out   std_logic;
    B_O   : out   std_logic
  );
end entity MUX_2X2;

architecture BEHAVIORAL of MUX_2X2 is

begin

  MUX : process (A_I, B_I, SEL_I) is
  begin

    if (SEL_I = '1') then
      A_O <= B_I;
      B_O <= A_I;
    else
      A_O <= A_I;
      B_O <= B_I;
    end if;

  end process MUX;

end architecture BEHAVIORAL;
