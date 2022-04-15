----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: BitCS - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Bitserial Compare Swap as an asynchronous variant.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity BITCS is
  port (
    A0     : in    std_logic; -- Serial input of operand A
    B0     : in    std_logic; -- Serial input of operand B
    A1     : out   std_logic; -- Serial output of operand A
    B1     : out   std_logic; -- Serial output of operand B
    START  : in    std_logic  -- Start signal marking start of new word.
  );
end entity BITCS;

architecture BEHAVIORAL of BITCS is

  -- The only known way to ensure encoding while allowing access to single bits.
  constant EQUAL   : std_logic_vector(1 downto 0)  := "00";
  constant GREATER : std_logic_vector(1 downto 0)  := "01";
  constant LESSER  : std_logic_vector(1 downto 0)  := "10";

  signal state     : std_logic_vector(1 downto 0);

begin

  -- MOORE_SFM -----------------------------------------------------------------------
  -- Implements an asynchonous Moore FSM with the modificationthe of current state
  -- being only dependent on the previous state if START is not set. Otherwise,
  -- acts as a normal FSM.
  ------------------------------------------------------------------------------------
  MOORE_SFM : process (A0, B0, START, state) is
  begin

    -- With START set, state is only dependent on input and assumes
    -- corresponding state.
    if (START = '1') then
      if (A0 = '1' and B0 = '0') then
        state <= GREATER;
      elsif (A0 = '0' and B0 = '1') then
        state <= LESSER;
      else
        state <= EQUAL;
      end if;
    else
      -- With START unset, only the EQUAL state allows transition into other
      -- states. Once the operand A is asserted as greater or lesser than B,
      -- the state remains "locked".
      case state is

        when EQUAL =>
          if (A0 = '1' and B0 = '0') then
            state <= GREATER;
          elsif (A0 = '0' and B0 = '1') then
            state <= LESSER;
          else
            state <= EQUAL;
          end if;

        when GREATER =>
          state <= GREATER;

        when LESSER =>
          state <= LESSER;

        when others =>
          state <= EQUAL;

      end case;

    end if;

  end process MOORE_SFM;

  OUTMUX : entity work.MUX_2X2
    port map (
      A0  => A0,
      B0  => B0,
      SEL => state(1),
      A1  => A1,
      B1  => B1
    );

end architecture BEHAVIORAL;
