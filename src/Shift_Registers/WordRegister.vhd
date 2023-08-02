----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: Mon Jul 24 14:59:15 2023
-- Design Name:
-- Module Name: WordRegister - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simple register component for a w-bits wide word. Used as a
-- delay element.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity WordRegister is
  generic (
    -- Data width.
    W : integer := 1
    );
  port (
    -- System Clock
    CLK_I    : in  std_logic;
    -- Reset
    RST_I    : in  std_logic;
    -- Enable
    ENABLE_I : in  std_logic;
    -- bit serial input
    D_I      : in  std_logic_vector(W-1 downto 0);
    -- bit-serial output
    D_O      : out std_logic_vector(W-1 downto 0)
    );
end entity WordRegister;

architecture BEHAVIORAL of WordRegister is

begin

  REG : process (CLK_I) is
  begin
    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        D_O <= (others => '0');
      else
        if (ENABLE_I = '1') then
          D_O <= D_I;
        end if;
      end if;
    end if;

  end process REG;

end architecture BEHAVIORAL;
