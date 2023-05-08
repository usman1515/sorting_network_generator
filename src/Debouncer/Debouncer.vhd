----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Debouncer - BEHAVIORAL
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Debounces input signal.
--
----------------------------------------------------------------------------------
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity DEBOUNCER is
  generic (
    -- Number of cycles until a change in output signal is allowed.
    TIMEOUT_CYCLES : integer := 50
  );
  port (
    -- System Clock signal
    CLK_I         : in    std_logic;
    -- Synchronous Reset
    RST_I         : in    std_logic;
    -- Bouncing input
    INPUT_I       : in    std_logic;
    -- Debounced ouput signal
    OUTPUT_O      : out   std_logic
  );
end entity DEBOUNCER;

architecture BEHAVIORAL of DEBOUNCER is

  signal count    : integer range 0 to TIMEOUT_CYCLES - 1;
  signal output : std_logic;

begin

  OUTPUT_O <= output;

  -- DEBOUNCE------------------------------------------------------------------
  -- Debounces a input_I signal by enforcing a time out after a signal change.
  -----------------------------------------------------------------------------
  DEBOUNCE : process (CLK_I) is
  begin

    if rising_edge(CLK_I) then
      if (RST_I = '1') then
        count    <= 0;
        output <= INPUT_I;
      else
        if (count < TIMEOUT_CYCLES - 1) then
          count <= count + 1;
        elsif (INPUT_I /= output) then
          count    <= 0;
          output <= INPUT_I;
        end if;
      end if;
    end if;

  end process DEBOUNCE;

end architecture BEHAVIORAL;
