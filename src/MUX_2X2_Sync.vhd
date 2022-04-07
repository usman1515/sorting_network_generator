----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: MUX_2X2_Synch - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Synchronous 2 to 2 MUX with enable.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity MUX_2X2_SYNCH is
  port (
    CLK  : in    std_logic;
    E    : in    std_logic;
    A0   : in    std_logic;
    B0   : in    std_logic;
    SEL  : in    std_logic;

    A1   : out   std_logic;
    B1   : out   std_logic
  );
end entity MUX_2X2_SYNCH;

architecture BEHAVIORAL of MUX_2X2_SYNCH is

begin

  MUX : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (E = '1') then
        if (SEL = '1') then
          A1 <= B0;
          B1 <= A0;
        else
          A1 <= A0;
          B1 <= B0;
        end if;
      end if;
    end if;

  end process MUX;

end architecture BEHAVIORAL;
