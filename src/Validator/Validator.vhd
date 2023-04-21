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

entity SUBWORD_VALIDATOR is
  generic (
    -- Number of w-Bit inputs.
    N  : integer := 4;
    SW : integer := 1
    );
  port (
    -- Clock signal
    CLK_I      : in  std_logic;
    -- Synchronous Reset
    RST_I      : in  std_logic;
    -- Enable signal
    ENABLE_I   : in  std_logic;
    -- Start signal indicating beginning of new word.
    START_I    : in  std_logic;
    -- N x W-Bit input treated as unsigned
    STREAM_I   : in  SLVArray(0 to N)(SW-1 downto 0);
    -- Bit indicating validity of received STREAM_I sequence. '1' indicates total ordering of STREAM_I
    -- sequence, '0' an order violation.
    IN_ORDER_O : out std_logic
    );
end entity SUBWORD_VALIDATOR;

architecture BEHAVIORAL of SUBWORD_VALIDATOR is

  signal pairwise_greater : std_logic_vector(0 to N-2);

begin


  SW_TO_SW_MUX : for i in 0 to N-2 generate
    SerialCompare_1 : entity work.SerialCompare
      generic map (
        SW => SW)
      port map (
        CLK_I        => CLK_I,
        OP_A_I       => STREAM_I(i),
        OP_B_I       => STREAM_I(i+1),
        IS_EQUAL_O   => open,
        IS_LESS_O    => open,
        IS_GREATER_O => pairwise_greater(i),
        START_I      => START_I);
  end generate SW_TO_SW_MUX;


-- VALIDATE--------------------------------------------------------------------
-- On reset, inputs are assumed to be IN_ORDER_O. Afterwards, all inputs are
-- pairwise compared in parallel in an interleaved fashion to deduce correct ordering.
-- Once an order violation is detected, IN_ORDER_O will only be set on reset.
-------------------------------------------------------------------------------
  VALIDATE : process(CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        IN_ORDER_O <= '1';  -- STREAM_I is assumed to be IN_ORDER_O at the beginning.
      else
        if (ENABLE_I = '1') then

          for i in 0 to N - 2 loop
            -- If any STREAM_I value is not in order, set IN_ORDER_O to 0
            if (pairwise_greater(i) = '1') then
              IN_ORDER_O <= '0';
            end if;

          end loop;

        end if;
      end if;
    end if;

  end process VALIDATE;

end architecture BEHAVIORAL;
