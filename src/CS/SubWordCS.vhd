----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SubWordCS - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Compare Swap wich compares subwords of size SW sequentially to
-- determine, whether operands need to be swapped or stay the same.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity SubWordCS is
  generic(
    -- Size of subword to be compared at a time.
    SW : integer := 2
);
  port (
    -- System Clock.
    CLK   : in    std_logic;
    -- Serial input of operand A
    A0    : in    std_logic_vector(SW - 1 downto 0);
    -- Serial input of operand B
    B0    : in    std_logic_vector(SW - 1 downto 0);
    -- Serial output of operand A
    A1    : out   std_logic_vector(SW - 1 downto 0);
    -- Serial output of operand B
    B1    : out   std_logic_vector(SW - 1 downto 0);
    -- Start signal marking start of new word. Acts similary to a reset.
    START : in    std_logic
  );
end entity SubWordCS;

architecture BEHAVIORAL of SubWordCS is

  -- The only known way to ensure encoding while allowing access to encoding bits.
  constant EQUAL         : std_logic_vector(1 downto 0)  := "00";
  constant GREATER       : std_logic_vector(1 downto 0)  := "01";
  constant LESSER        : std_logic_vector(1 downto 0)  := "10";

  signal state           : std_logic_vector(1 downto 0);
  signal next_state      : std_logic_vector(1 downto 0);
  signal a1_i            : std_logic_vector(SW - 1 downto 0);
  signal b1_i            : std_logic_vector(SW - 1 downto 0);

begin
  SW_TO_SW_MUX : for i in  0 to SW-1 generate
    MUX_2X2_1 : entity work.mux_2x2
      port map (
      A0  => A0(i),
      B0  => B0(i),
      SEL => next_state(1),
      A1  => a1_i(i),
      B1  => b1_i(i)
    );
  end generate SW_TO_SW_MUX;

  -- MUXBUFFER -------------------------------------------------------------------
  -- Enforces FF at A1,B1 output.
  --------------------------------------------------------------------------------
  MUXBUFFER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      A1    <= a1_i;
      B1    <= b1_i;
      state <= next_state;
    end if;

  end process MUXBUFFER;

  -- MOORE_FSM -----------------------------------------------------------------------
  -- Implements an asynchonous Moore FSM with the modificationthe of current state
  -- being only dependent on the previous state if START is not set. Otherwise,
  -- acts as a normal FSM.
  ------------------------------------------------------------------------------------
  MOORE_FSM : process (A0, B0, START, state) is
  begin

    -- With START set, state is only dependent on input and assumes
    -- corresponding state.
    if (START = '1') then
      if ( unsigned(A0) > unsigned(B0) ) then
        next_state <= GREATER;
      elsif ( unsigned(A0) < unsigned(B0)) then
        next_state <= LESSER;
      else
        next_state <= EQUAL;
      end if;
    else
      -- With START unset, only the EQUAL state allows transition into other
      -- states. Once the operand A is asserted as greater or lesser than B,
      -- the state remains "locked".
      case state is

        when EQUAL =>
          if ( unsigned(A0) > unsigned(B0)) then
            next_state <= GREATER;
          elsif ( unsigned(A0) < unsigned(B0)) then
            next_state <= LESSER;
          else
            next_state <= EQUAL;
          end if;

        when GREATER =>
          next_state <= GREATER;

        when LESSER =>
          next_state <= LESSER;

        when others =>
          next_state <= EQUAL;

      end case;

    end if;

  end process MOORE_FSM;

end architecture BEHAVIORAL;
