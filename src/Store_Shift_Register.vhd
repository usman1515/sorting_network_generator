----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: STORE_SHIFT_REGISTER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift Register with w-bit parallel store functionality, a w-bit
-- deserializer.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity STORE_SHIFT_REGISTER is
  generic (
    -- Width of parallel input/ word.
    W : integer := 8
  );
  port (
    -- System Clock
    CLK                    : in    std_logic;
    -- Enable
    E                      : in    std_logic;
    -- Load signal
    STORE                   : in    std_logic;
    -- bit-serial input
    SER_INPUT              : in    std_logic;
    -- w-bit parallel output
    PAR_OUTPUT             : out   std_logic_vector(W - 1 downto 0)
  );
end entity STORE_SHIFT_REGISTER;

architecture BEHAVIORAL of STORE_SHIFT_REGISTER is

  signal sreg : std_logic_vector(W - 1 downto 0);

begin

  -- SHIFT_STORE----------------------------------------------------------------
  -- When enabled, shifts value from SER_INPUT into register and outputs
  -- content of sreg when STORE is set.
  ------------------------------------------------------------------------------
  SHIFT_STORE : process is
  begin

    if (rising_edge(CLK)) then
      if (E = '1') then
        sreg <= sreg(sreg'high - 1 downto sreg'low) & SER_INPUT;
      end if;

      if (STORE = '1') then
        PAR_OUTPUT <= sreg;
      end if;
    end if;

  end process SHIFT_STORE;

end architecture BEHAVIORAL;
