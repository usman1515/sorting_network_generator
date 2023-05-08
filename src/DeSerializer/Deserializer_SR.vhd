-------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: DeserializerSW_SR - Structural
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Deserializer for N W-bit values in parallel. Uses Store Shift Registers.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity DESERIALIZER_SR is
  generic (
    -- Number of values serialized in parallel.
    N          : integer;
    -- Width of parallel input/ word.
    W          : integer := 8;
    -- Length of subwords to be output at a time.
    SW         : integer := 1
  );
  port (
    -- System Clock
    CLK_I    : in    std_logic;
    -- Synchonous Reset
    RST_I    : in    std_logic;
    -- Enable
    ENABLE_I : in    std_logic;
    -- Start signal from network output.
    START_I  : in    std_logic;
    -- sub word parallel or bit serial input
    STREAM_I : in    SLVArray(0 to N - 1)(SW - 1 downto 0);
    -- Data valid signal
    VALID_O  : out   std_logic;
    -- Data ready signal
    READY_I  : in    std_logic;
    -- w-bit parallel output
    DATA_O   : out   SLVArray(0 to N - 1)(W - 1 downto 0)
  );
end entity DESERIALIZER_SR;

architecture STRUCTURAL of DESERIALIZER_SR is

  type state_t is (IDLE, RUNNING);

  signal state, next_state : state_t;

  constant LIMIT           : integer := ((W + SW - 1) / SW) - 1;
  signal   count           : integer range 0 to LIMIT;

  signal run               : std_logic;

begin

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable. Used for timing the
  -- process of serialization and runs only during RUNNING state.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK_I) is
  begin

    if rising_edge(CLK_I) then
      if (RST_I = '1' or ENABLE_I = '0') then
        count <= LIMIT;
      else
        if (state = RUNNING or (state=IDLE and START_I = '1') ) then
          if (count = 0) then
            count <= LIMIT;
          else
            count <= count - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- FSM_CORE---------------------------------------------------------------------
  -- Synchronous FSM register.
  --------------------------------------------------------------------------------
  FSM_CORE : process (CLK_I) is
  begin

    if rising_edge(CLK_I) then
      if (RST_I = '1') then
        state   <= IDLE;
      else
        if (ENABLE_I = '1') then
          state <= next_state;
        else
          state <= IDLE;
        end if;
      end if;
    end if;

  end process FSM_CORE;

  -- FSM--------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  FSM : process (RST_I, START_I, READY_I, state, count) is
  begin

    if (RST_I = '1') then
      next_state <= IDLE;
      run        <= '0';
      VALID_O <= '0';
    else
      next_state <= state;
      run        <= '0';
      VALID_O <= '0';

      case state is

        when IDLE =>
          if (START_I = '1') then
            run        <= '1';
            next_state <= RUNNING;
          end if;

        when RUNNING =>
          run <= '1';
          if (count = 0) then
            VALID_O <= '1';
          end if;

      end case;

    end if;

  end process FSM;

  STORESHIFTREGISTERS : for i in 0 to N - 1 generate

    STORE_SHIFT_REGISTER_1 : entity work.store_shift_register
      generic map (
        W  => W,
        SW => SW
      )
      port map (
        CLK_I    => CLK_I,
        RST_I    => RST_I,
        RUN_I    => run,
        STREAM_I => STREAM_I(i),
        DATA_O   => DATA_O(i)
      );

  end generate STORESHIFTREGISTERS;

end architecture STRUCTURAL;
