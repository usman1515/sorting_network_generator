----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SHIFT_REGISTER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift register of w-width with serial in-/output. Used as delay
-- element.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity SHIFT_REGISTER is
  generic (
    -- Length of the shift register.
    LENGTH : integer := 8
  );
  port (
    -- System Clock
    CLK        : in    std_logic;
    -- Reset
    RST        : in    std_logic;
    -- Enable
    E          : in    std_logic;
    -- bit serial input
    SER_INPUT  : in    std_logic;
    -- bit-serial output
    SER_OUTPUT : out   std_logic
  );
end entity SHIFT_REGISTER;

architecture BEHAVIORAL of SHIFT_REGISTER is

  signal sreg : std_logic_vector(LENGTH - 1 downto 0);

begin

  -- SHIFT------------------------------------------------------------------------
  -- Shifts value from SER_INPUT into sreg and MSB of sreg out to SER_OUTPUT.
  --------------------------------------------------------------------------------
  SHIFT : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        sreg <= (others => '0');
      else
        if (E = '1') then
          sreg <= sreg(sreg'high - 1 downto sreg'low) & SER_INPUT;
        end if;
      end if;
    end if;

  end process SHIFT;

  -- ASYNC_OUTPUT---------------------------------------------------------------
  -- Asynchronously outputs the MSB of sreg.
  -----------------------------------------------------------------------------
  ASYNC_OUTPUT : process (sreg) is
  begin
    SER_OUTPUT <= sreg(sreg'high);
  end process ASYNC_OUTPUT;

end architecture BEHAVIORAL;
