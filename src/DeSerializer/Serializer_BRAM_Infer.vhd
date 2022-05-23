----------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Serializer_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Serializer Component using an array to infer BRAM.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

library work;
  use work.CustomTypes.all;

entity SERIALIZER_BRAM is
  generic (
    -- Number of values serialized in parallel.
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8
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
    PAR_INPUT             : in    SLVArray(0 to N - 1)(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   std_logic_vector(0 to N - 1)
  );
end entity SERIALIZER_BRAM;

architecture BEHAVIORAL of SERIALIZER_BRAM is

  function sub_hold (a : integer; b : integer) return integer is
  begin
    if b > a then
      return 0;
    else
      return a - b;
    end if;

  end function sub_hold;

  function get_num_bits (a : integer) return integer is
  begin

    if (a = 1) then
      return 1;
    else
      return integer (ceil (log2 (real (a))));
    end if;

  end function get_num_bits;

  -- WARNING: No checks prevent a address depth exceeding the allowed bounds of
  -- the BRAM block !

  signal addr             : integer range 0 to N * W - 1;
  signal bram             : SLVArray(0 to N - 1)( W-1 downto 0 );

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or LOAD = '1') then
        addr <= W - 2 ;
      else
        if (E = '1') then
          addr <= sub_hold(addr, 1);
        end if;
      end if;
    end if;

  end process COUNTER;

  BRAM_PROC : process (CLK) is
  begin

    if rising_edge(CLK) then
      if (RST ='0') then
        if (LOAD = '1') then
          bram <= PAR_INPUT;
        end if;
      end if;
    end if;

  end process BRAM_PROC;
  BRAM_OUT : process(RST,LOAD,PAR_INPUT, bram, addr)
  begin
      if (RST ='1') then
        SER_OUTPUT <= (others => '0');
      else
        if (LOAD = '1') then

          for i in 0 to N - 1 loop

            SER_OUTPUT(i) <= PAR_INPUT(i)(W-1);

          end loop;

        else

          for i in 0 to N - 1 loop

            SER_OUTPUT(i) <= bram(i)(addr);

          end loop;

        end if;
      end if;

  end process BRAM_OUT;
end architecture BEHAVIORAL;
