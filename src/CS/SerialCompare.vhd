----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 04/13/2023 02:46:11 PM
-- Design Name:
-- Module Name: SerialCompare - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Compare element wich compares subwords of size SW sequentially to
-- determine, whether operands are equal, less, or greater.
--
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity SerialCompare is
  generic(
    -- Size of subword to be compared at a time.
    SW : integer := 1
    );
  port (
    -- System Clock.
    CLK_I        : in  std_logic;
    -- Serial input of operand A
    OP_A_I       : in  std_logic_vector(SW - 1 downto 0);
    -- Serial input of operand B
    OP_B_I       : in  std_logic_vector(SW - 1 downto 0);
    -- High if A == B, zero otherwise.
    IS_EQUAL_O   : out std_logic;
    -- High if A < B, zero otherwise.
    IS_LESS_O    : out std_logic;
    -- High if A > B, zero otherwise.
    IS_GREATER_O : out std_logic;
    -- Start signal marking start of new word. Acts similary to a reset.
    START_I      : in  std_logic
    );
end entity SerialCompare;

architecture BEHAVIORAL of SerialCompare is

  -- The only known way to ensure encoding while allowing access to encoding bits.
  constant EQUAL   : std_logic_vector(1 downto 0) := "00";
  constant GREATER : std_logic_vector(1 downto 0) := "01";
  constant LESSER  : std_logic_vector(1 downto 0) := "10";

  signal state      : std_logic_vector(1 downto 0);
  signal next_state : std_logic_vector(1 downto 0);

begin

  IS_EQUAL_O   <= '1' when next_state = EQUAL   else '0';
  IS_LESS_O    <= '1' when next_state = LESSER  else '0';
  IS_GREATER_O <= '1' when next_state = GREATER else '0';

  FSM_CORE : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      state <= next_state;
    end if;

  end process FSM_CORE;

  -- MOORE_FSM -----------------------------------------------------------------------
  -- Implements an asynchonous Moore FSM with the modification of the of current state
  -- being only dependent on the previous state if START_I is not set. Otherwise,
  -- acts as a normal FSM.
  ------------------------------------------------------------------------------------
  MOORE_FSM : process (OP_A_I, OP_B_I, START_I, state) is
  begin

    -- With START_I set, state is only dependent on input and assumes
    -- corresponding state.
    if (START_I = '1') then
      if (unsigned(OP_A_I) > unsigned(OP_B_I)) then
        next_state <= GREATER;
      elsif (unsigned(OP_A_I) < unsigned(OP_B_I)) then
        next_state <= LESSER;
      else
        next_state <= EQUAL;
      end if;
    else
      -- With START unset, only the EQUAL state allows transition into other
      -- states. Once the operand OP_A_I is asserted as greater or lesser than OP_B_I,
      -- the state remains "locked".
      case state is

        when EQUAL =>
          if (unsigned(OP_A_I) > unsigned(OP_B_I)) then
            next_state <= GREATER;
          elsif (unsigned(OP_A_I) < unsigned(OP_B_I)) then
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

  end process;

end architecture BEHAVIORAL;
