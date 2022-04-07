----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: CYCLE_TIMER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Timer Component for START signal generation.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity CYCLE_TIMER is
  generic (
    W : integer := 8                    -- Width of input bits
  );
  port (
    CLK     : in    std_logic;
    RST     : in    std_logic;                -- Synchronous reset
    E       : in    std_logic;                -- Enable signal, halts operation if unset
    START   : out   std_logic                 -- Sorting start signal
  );
end entity CYCLE_TIMER;

architecture BEHAVIORAL of CYCLE_TIMER is

  signal count : integer range 0 to W - 1;

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable. Sets START at beginning.
  --------------------------------------------------------------------------------
  COUNTER : process is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or count = W - 1) then
        count <= 0;
      else
        if (E = '1') then
          count <= count + 1;
        end if;
      end if;
      if (count = 0) then
        START <= '0';
      else
        START <= '1';
      end if;
    end if;

  end process COUNTER;

end architecture BEHAVIORAL;
