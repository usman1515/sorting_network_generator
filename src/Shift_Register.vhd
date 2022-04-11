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
    -- Width of parallel input/ word.
    W : integer := 8
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

  signal reg : std_logic_vector(W - 1 downto 0);

begin

  -- SHIFT------------------------------------------------------------------------
  -- Shifts value from SER_INPUT into sreg and MSB of sreg out to SER_OUTPUT.
  --------------------------------------------------------------------------------
  SHIFT : process is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        reg <= (others => '0');
      else
        if (E = '1') then
          reg <= reg(reg'high - 1 downto reg'low) & SER_INPUT;
        end if;
      end if;
      SER_OUTPUT <= reg(reg'high);
    end if;

  end process SHIFT;

end architecture BEHAVIORAL;
