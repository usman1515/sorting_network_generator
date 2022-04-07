----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LOAD_SHIFT_REGISTER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift register of w-width with parallel load, a w-bit serializer.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity LOAD_SHIFT_REGISTER is
  generic (
    -- Width of parallel input/ word.
    W : integer := 8
  );
  port (
    -- System Clock
    CLK                   : in    std_logic;
    -- Enable
    E                     : in    std_logic;
    -- Load signal
    LOAD                  : in    std_logic;
    -- w-bit parallel input
    PAR_INPUT             : in    std_logic_vector(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   std_logic
  );
end entity LOAD_SHIFT_REGISTER;

architecture BEHAVIORAL of LOAD_SHIFT_REGISTER is

  signal sreg : std_logic_vector(W - 2 downto 0); -- Shift register.
  -- We can make do with one bit less as the first PAR_INPUT bit
  -- is immediatly send to SER_OUTPUT.

begin

  -- SHIFT-CONTENT----------------------------------------------------------------
  -- Synchronously loads value from PAR_INPUT into sreg or shifts out content of
  -- sreg to the left.
  --------------------------------------------------------------------------------
  SHIFT_CONTENT : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (E = '1') then
        if (LOAD = '0') then
          sreg(sreg'high downto sreg'low + 1) <= sreg(sreg'high - 1 downto sreg'low);
        else
          sreg <= PAR_INPUT(PAR_INPUT'high - 1 downto PAR_INPUT'low);
        end if;
      end if;
    end if;

  end process SHIFT_CONTENT;

  -- ASYNC_OUTPUT---------------------------------------------------------------
  -- Asynchronously outputs either the MSB of sreg or the MSB of PAR_INPUT
  -- depeding on LOAD. Likely infers a latch...
  -----------------------------------------------------------------------------
  ASYNC_OUTPUT : process (LOAD, sreg, PAR_INPUT) is
  begin

    if (LOAD = '1') then
      SER_OUTPUT <= PAR_INPUT(PAR_INPUT'high);
    else
      SER_OUTPUT <= sreg(sreg'high);
    end if;

  end process ASYNC_OUTPUT;

end architecture BEHAVIORAL;
