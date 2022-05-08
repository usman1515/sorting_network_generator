----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LoadMUXFF - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity LOAD_MUX_FF is
  generic (
    -- Width of parallel input/ word.
    W  : integer := 8;
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
    SER_OUTPUT            : out   std_logic_vector(SW - 1 downto 0)
  );
end entity LOAD_MUX_FF;

architecture BEHAVIORAL of LOAD_MUX_FF is

  signal buf : std_logic_vector(SW * (W / SW) - 1 downto 0); -- Shift register.
  -- Since some bits are immediatly sent to output upon loading, we can make do
  -- with less.
  signal count : integer range 0 to W / SW - 1;

begin

  process is
  begin

    wait until rising_edge(CLK);

    if (LOAD = '1' or count = W - 1) then
      count <= 0;
    else
      if (E = '1') then
        count <= count + 1;
      end if;
    end if;

  end process;

  process is
  begin

    wait until rising_edge(CLK);

    if (LOAD = '1') then
      buf <= PAR_INPUT(PAR_INPUT'high downto PAR_INPUT'low);
    end if;

  end process;

  process (LOAD, buf, PAR_INPUT) is
  begin

    if (LOAD = '1') then
      SER_OUTPUT <= PAR_INPUT(0);
    else
      SER_OUTPUT <= buf(count);
    end if;

  end process;

end architecture BEHAVIORAL;
