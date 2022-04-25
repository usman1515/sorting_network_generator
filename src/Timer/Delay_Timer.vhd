--------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: DELAY_TIMER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Timer component which delays input signal for delay cycles.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity DELAY_TIMER is
  generic (
    -- Delay in cycles.
    DELAY : integer := 8
  );
  port (
    CLK         : in    std_logic;
    -- Synchronous reset
    RST         : in    std_logic;
    -- Enable signal, halts operation if unset
    E           : in    std_logic;
    -- Input signal A.
    A           : in    std_logic;
    -- Delayed signal A.
    A_DELAYED   : out   std_logic
  );
end entity DELAY_TIMER;

architecture BEHAVIORAL of DELAY_TIMER is

  signal count        : integer range 0 to DELAY - 1;
  signal sig_received : std_logic;

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable. FF sig_received acts as a secondary
  -- enable condition which will cause A_DELAYED to be set for one cycle on
  -- counter overflow.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is

  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        count        <= 0;
        sig_received <= '0';
        A_DELAYED    <= '0';
      else
        if (E = '1') then
          if (sig_received = A) then
            if (count = DELAY - 1) then
              A_DELAYED <= sig_received;
            else
              count <= count + 1;
            end if;
          else
            sig_received <= A;
            count <= 0;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

end architecture BEHAVIORAL;
