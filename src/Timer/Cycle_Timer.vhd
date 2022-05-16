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
    -- Width of input bits
    W  : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1;
    -- Delay after overflow until START is set to high.
    DELAY: integer := 0
  );
  port (
    CLK     : in    std_logic;
    RST     : in    std_logic;                -- Synchronous reset
    E       : in    std_logic;                -- Enable signal, halts operation if unset
    START   : out   std_logic                 -- Sorting start signal
  );
end entity CYCLE_TIMER;

architecture BEHAVIORAL of CYCLE_TIMER is

  signal count : integer range 0 to ((W + SW - 1) / SW) - 1;

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable. Sets START at beginning.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        count <= 0;
      else
        if (E = '1') then
          if (count = ((W + SW - 1) / SW) - 1) then
            count <= 0;
          else
            count <= count + 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- SETSTART---------------------------------------------------------------------
  -- Asynchronous process setting start if counter is zero so long as the
  -- counter is not reset and enabled.
  --------------------------------------------------------------------------------
  SETSTART : process (count, RST, E) is
  begin

    if (RST = '0' and E = '1') then
      if (count = DELAY) then
        START <= '1';
      else
        START <= '0';
      end if;
    else
      START <= '0';
    end if;

  end process SETSTART;

end architecture BEHAVIORAL;
