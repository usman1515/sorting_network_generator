----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LOAD_SHIFT_REGISTER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift register of with parallel load, a subword serializer.
--
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity LOAD_SHIFT_REGISTER is
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
    ENABLE_I : in  std_logic;
    -- Load signal
    LOAD_I   : in  std_logic;
    -- w-bit parallel input
    DATA_I   : in  std_logic_vector(W - 1 downto 0);
    -- subword parallel to bit-serial output
    STREAM_O : out std_logic_vector(SW - 1 downto 0)
    );
end entity LOAD_SHIFT_REGISTER;

architecture BEHAVIORAL of LOAD_SHIFT_REGISTER is

  signal sreg : std_logic_vector(W - 1 downto 0) := (others => '0');  --( SW * (W / SW) - 1 downto 0); -- Shift register.

begin

  -- SHIFT-CONTENT----------------------------------------------------------------
  -- Synchronously loads value from DATA_I into sreg or shifts out content of
  -- sreg to the left.
  --------------------------------------------------------------------------------
  SHIFT_CONTENT : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        sreg <= (others => '0');
      else
        if (ENABLE_I = '1') then
          if (LOAD_I = '0') then
            sreg(sreg'high downto sreg'low + SW) <= sreg(sreg'high - SW downto sreg'low);
          else
            if (W mod SW /= 0) then
              sreg(sreg'high downto sreg'low + (SW mod W) - 1) <=
                DATA_I(DATA_I'high - (W mod SW) downto DATA_I'low);
            else
              sreg(sreg'high downto sreg'low + SW) <=
                DATA_I(DATA_I'high - SW downto DATA_I'low);
            end if;
          end if;
        end if;
      end if;
    end if;

  end process SHIFT_CONTENT;

  -- ASYNC_OUTPUT---------------------------------------------------------------
  -- Asynchronously outputs either the MSB of sreg or the MSB of DATA_I
  -- depeding on LOAD_I.
  -----------------------------------------------------------------------------
  ASYNC_OUTPUT : process (LOAD_I, sreg, DATA_I) is
  begin

    if (LOAD_I = '1') then
      if (W mod SW > 0) then
        STREAM_O(SW - 1 downto W mod SW) <= (others => '0');
        STREAM_O(W mod SW - 1 downto 0)  <= DATA_I(DATA_I'high downto SW * (W / SW));
      else
        STREAM_O <= DATA_I(W - 1 downto W - SW);
      end if;
    else
      STREAM_O <= sreg(sreg'high downto sreg'high - (SW - 1));
    end if;

  end process ASYNC_OUTPUT;

end architecture BEHAVIORAL;
