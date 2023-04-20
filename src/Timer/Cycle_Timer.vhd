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
    W     : integer := 8;
    -- Length of subwords to be output at a time.
    SW    : integer := 1
    );
  port (
    CLK_I    : in  std_logic;
    RST_I    : in  std_logic;   -- Synchronous reset
    ENABLE_I : in  std_logic;   -- Enable signal, halts operation if unset
    START_O  : out std_logic    -- Sorting start_O signal
    );
end entity CYCLE_TIMER;

architecture BEHAVIORAL of CYCLE_TIMER is
  -- limit = ceil(W/SW)
  constant limit : integer := ((W + SW - 1) / SW);
  signal count : integer range 0 to ((W + SW - 1) / SW) - 1;

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        count <= 0;
      else
        if (ENABLE_I = '1') then
          if (count = 0) then
            count <= limit - 1;
          else
            count <= count - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- SETSTART---------------------------------------------------------------------
  -- Asynchronous process setting start_O if counter is zero so long as the
  -- counter is not reset and enabled.
  --------------------------------------------------------------------------------
  SETSTART : process (count, RST_I, ENABLE_I) is
  begin

    if (RST_I = '0' and ENABLE_I = '1') then
      if (count = 0) then
        START_O <= '1';
      else
        START_O <= '0';
      end if;
    else
      START_O <= '0';
    end if;

  end process SETSTART;

end architecture BEHAVIORAL;
