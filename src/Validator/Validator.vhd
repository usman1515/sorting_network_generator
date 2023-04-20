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
    -- Number of w-Bit inputs.
    N : integer := 4;
    SW : integer := 1
    );
  port (
    -- Clock signal
    CLK   : in  std_logic;
    -- Synchronous Reset
    RST   : in  std_logic;
    -- Enable signal
    E     : in  std_logic;
    -- Start signal indicating beginning of new word.
    START : in  std_logic;
    -- N x W-Bit input treated as unsigned
    INPUT : in  SLVArray(0 to N)(SW-1 downto 0);
    -- Bit indicating validity of received input sequence. '1' indicates total ordering of input
    -- sequence, '0' an order violation.
    VALID : out std_logic
    );
end entity VALIDATOR;

architecture BEHAVIORAL of VALIDATOR is

  signal pairwise_greater : std_logic_vector(0 to N-2);

begin


  SW_TO_SW_MUX : for i in 0 to N-2 generate
    SerialCompare_1 : entity work.SerialCompare
      generic map (
        SW => SW)
      port map (
        CLK        => CLK,
        A          => INPUT(i),
        B          => INPUT(i+1),
        IS_EQUAL   => open,
        IS_LESS    => open,
        IS_GREATER => pairwise_greater(i),
        START      => START);
  end generate SW_TO_SW_MUX;


-- VALIDATE--------------------------------------------------------------------
-- On reset, inputs are assumed to be valid. Afterwards, all inputs are
-- pairwise compared in parallel in an interleaved fashion to deduce correct ordering.
-- Once an order violation is detected, valid will only be set on reset.
-------------------------------------------------------------------------------
  VALIDATE : process(CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        VALID <= '1';  -- Input is assumed to be valid at the beginning.
      else
        if (E = '1') then

          for i in 0 to N - 2 loop
            -- If any input value is not in order, set valid to 0
            if (pairwise_greater(i) = '1') then
              VALID <= '0';
            end if;

          end loop;

        end if;
      end if;
    end if;

  end process VALIDATE;

end architecture BEHAVIORAL;
