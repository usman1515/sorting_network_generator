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
    CLK_I    : in  std_logic;
    -- Synchonous Reset
    RST_I    : in  std_logic;
    -- Enable
    RUN_I : in  std_logic;
    -- bit-serial input
    STREAM_I : in  std_logic_vector(SW - 1 downto 0);
    -- w-bit parallel output
    DATA_O   : out std_logic_vector(W - 1 downto 0)
    );
end entity STORE_SHIFT_REGISTER;

architecture BEHAVIORAL of STORE_SHIFT_REGISTER is

  -- Shift Register
  signal sreg  : std_logic_vector(W - 1 downto 0);

begin

  DATA_O <= sreg;

  -- SHIFT_STORE----------------------------------------------------------------
  -- When enabled, shifts value from STREAM_I into register.
  ------------------------------------------------------------------------------
  SHIFT_STORE : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        sreg   <= (others => '0');
      else
        if (RUN_I = '1') then
          sreg <= sreg(sreg'high - SW downto sreg'low) & STREAM_I;
        end if;
      end if;
    end if;

  end process SHIFT_STORE;

end architecture BEHAVIORAL;
