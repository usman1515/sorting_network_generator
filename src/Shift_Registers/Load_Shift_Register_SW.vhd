----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LOAD_SHIFT_REGISTER_SW - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift register of with parallel load, a subword serializer.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity LOAD_SHIFT_REGISTER_SW is
  generic (
    -- Width of parallel input/ word.
    W : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                   : in    std_logic;
    -- Synchonous Reset
    RST                   : in    std_logic;
    -- Enable
    E                     : in    std_logic;
    -- Load signal
    LOAD                  : in    std_logic;
    -- w-bit parallel input
    PAR_INPUT             : in    std_logic_vector(W - 1 downto 0);
    -- subword parallel to bit-serial output
    SER_OUTPUT            : out   std_logic_vector(SW -1 downto 0)
  );
end entity LOAD_SHIFT_REGISTER_SW;

architecture BEHAVIORAL of LOAD_SHIFT_REGISTER_SW is

  signal sreg : std_logic_vector(W - SW downto 0); -- Shift register.
  -- We can make do with the number of subword bits less as the first PAR_INPUT bits
  -- are immediatly send to SER_OUTPUT.

begin

  -- SHIFT-CONTENT----------------------------------------------------------------
  -- Synchronously loads value from PAR_INPUT into sreg or shifts out content of
  -- sreg to the left.
  --------------------------------------------------------------------------------
  SHIFT_CONTENT : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        sreg <= (others => '0');
      else
        if (E = '1') then
          if (LOAD = '0') then
            sreg(sreg'high downto sreg'low + SW) <= sreg(sreg'high - SW downto sreg'low);
          else
            sreg <= PAR_INPUT(SW * (W / SW) - 1 downto PAR_INPUT'low);
          end if;
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
      if (W mod SW > 0) then
          SER_OUTPUT(SW - 1 downto SW - W mod SW) <= (others => '0');
          SER_OUTPUT(W mod SW -1 downto 0) <= PAR_INPUT(PAR_INPUT'high downto SW * (W / SW ) );
        else
          SER_OUTPUT <= PAR_INPUT(W - 1 downto W - SW);
        end if;
    else
      SER_OUTPUT <= sreg(sreg'high downto sreg'high - (SW-1));
    end if;

  end process ASYNC_OUTPUT;

end architecture BEHAVIORAL;
