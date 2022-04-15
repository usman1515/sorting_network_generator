----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Validator - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Validates order of input sequence. Treats values at input as unsigned.
--
----------------------------------------------------------------------------------

library ieee;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity VALIDATOR is
  generic (
    -- Bit-Width of input values.
    W : integer := 8;
    -- Number of w-Bit inputs.
    N : integer := 4
  );
  port (
    -- Clock signal
    CLK   : in    std_logic;
    -- Synchronous Reset
    RST     : in    std_logic;
    -- Enable signal
    E     : in    std_logic;
    -- N x W-Bit input treated as unsigned
    INPUT : in    SLVArray(N - 1 downto 0)(W - 1 downto 0);
    -- Bit indicating validity of received input sequence. '1' indicates total ordering of input
    -- sequence, '0' an order violation.
    VALID : out   std_logic
  );
end entity VALIDATOR;

architecture BEHAVIORAL of VALIDATOR is

begin

-- VALIDATE--------------------------------------------------------------------
-- On reset, inputs are assumed to be valid. Afterwards, all inputs are
-- pairwise compared in parallel in an interleaved fashion to deduce correct ordering.
-- Once an order violation is detected, valid will only be set on reset.
-------------------------------------------------------------------------------
  VALIDATE : process(CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        VALID <= '1'; -- Input is assumed to be valid at the beginning.
      else
        if (E = '1') then

          for i in 0 to N - 2 loop

            -- If any input value is not in order, set valid to 0
            if (unsigned(INPUT(i)) > unsigned(INPUT(i + 1))) then
              VALID <= '0';
            end if;

          end loop;

        end if;
      end if;
    end if;

  end process VALIDATE;

end architecture BEHAVIORAL;
