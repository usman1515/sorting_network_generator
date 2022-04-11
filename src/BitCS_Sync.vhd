----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: BitCS_Sync - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Bitserial Compare Swap in the traditional synchronous variant.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity BITCS_SYNC is
  port (
    -- System Clock.
    CLK   : in    std_logic;
    -- Serial input of operand A
    A0    : in    std_logic;
    -- Serial input of operand B
    B0    : in    std_logic;
    -- Serial output of operand A
    A1    : out   std_logic;
    -- Serial output of operand B
    B1    : out   std_logic;
    -- Start signal marking start of new word. Acts essentially as a reset.
    START : in    std_logic
  );
end entity BITCS_SYNC;

architecture BEHAVIORAL of BITCS_SYNC is

  -- The only known way to ensure encoding while allowing access to encoding bits.
  constant EQUAL    : std_logic_vector(1 downto 0)  := "00";
  constant GREATER  : std_logic_vector(1 downto 0)  := "01";
  constant LESSER   : std_logic_vector(1 downto 0)  := "10";

  signal state      : std_logic_vector(1 downto 0);
  signal a1_i       : std_logic;
  signal b1_i       : std_logic;

begin

  MUX_2X2_1 : entity work.MUX_2X2
    port map (
      A0  => A0,
      B0  => B0,
      SEL => state(1),
      A1  => A1,
      B1  => B1
    );

  -- MOORE_FSM -----------------------------------------------------------------------
  -- Implements an asynchonous Moore FSM with the modificationthe of current state
  -- being only dependent on the previous state if START is not set. Otherwise,
  -- acts as a normal FSM.
  ------------------------------------------------------------------------------------
  MOORE_FSM : process (CLK) is
  begin

    if (rising_edge(CLK)) then
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
    end if;

  end process MOORE_FSM;

end architecture BEHAVIORAL;
