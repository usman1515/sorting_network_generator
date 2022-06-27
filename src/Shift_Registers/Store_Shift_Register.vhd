---------------------------------------------------------------------------------
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
    W  : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                     : in    std_logic;
    -- Synchonous Reset
    RST                     : in    std_logic;
    -- Enable
    E                       : in    std_logic;
    -- Load signal
    STORE                   : in    std_logic;
    -- bit-serial input
    SER_INPUT               : in    std_logic_vector(SW - 1 downto 0);
    -- w-bit parallel output
    PAR_OUTPUT              : out   std_logic_vector(W - 1 downto 0)
  );
end entity STORE_SHIFT_REGISTER;

architecture BEHAVIORAL of STORE_SHIFT_REGISTER is

  -- Shift Register
  -- sreg must be two additional registers deep to keep timing in line with
  -- the BRAM variant.
  signal sreg         : std_logic_vector(W + SW*2 - 1 downto 0);
  -- Delayed store signal required for the same reason as above.
  signal store_i      : std_logic_vector(2 - 1 downto 0);

begin

  SET_LOAD_DELAYED : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      store_i(0)                                   <= STORE;
      store_i(store_i'high downto store_i'low + 1) <= store_i(store_i'high - 1 downto store_i'low);
    end if;

  end process SET_LOAD_DELAYED;

  -- SHIFT_STORE----------------------------------------------------------------
  -- When enabled, shifts value from SER_INPUT into register and outputs
  -- content of sreg when STORE is set.
  ------------------------------------------------------------------------------
  SHIFT_STORE : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        sreg       <= (others => '0');
        PAR_OUTPUT <= (others => '0');
      else
        if (E = '1') then
          sreg <= sreg(sreg'high - SW downto sreg'low) & SER_INPUT;
        end if;

        if (store_i(store_i'high) = '1') then
          PAR_OUTPUT <= sreg(sreg'high downto sreg'high - (W - 1));
        end if;
      end if;
    end if;

  end process SHIFT_STORE;

end architecture BEHAVIORAL;
