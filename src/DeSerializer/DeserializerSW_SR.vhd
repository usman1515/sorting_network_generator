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

entity DESERIALIZERSW_SR is
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
    CLK_I    : in  std_logic;
    -- Synchonous Reset
    RST_I    : in  std_logic;
    -- Enable
    ENABLE_I : in  std_logic;
    -- Start signal from network output.
    START_I  : in  std_logic;
    -- sub word parallel or bit serial input
    STREAM_I : in  SLVArray(0 to N - 1)(SW -1 downto 0);
    -- Data valid signal
    VALID_O  : out std_logic;
    -- Data ready signal
    READY_I  : in  std_logic;
    -- w-bit parallel output
    DATA_O   : out SLVArray(0 to N - 1)(W - 1 downto 0);
    -- Stall signal indicating backpressure at the sorter end.
    STALL_O  : out std_logic
    );
end entity DESERIALIZERSW_SR;

architecture STRUCTURAL of DESERIALIZERSW_SR is


  type state_t is (IDLE, RUNNING, DONE);
  signal state, next_state : state_t;

  constant limit : integer := ((W+SW-1)/SW) - 1;
  signal count   : integer range 0 to limit;

  signal store, run : std_logic;
begin

  STALL_O <= '1' when state = "DONE" else '0';

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable. Used for timing the
  -- process of serialization and runs only during RUNNING state.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK_I) is
  begin
    if (RST_I = '1') then
      count <= limit;
    else
      if (ENABLE_I = '1') then
        if (run = '1') then
          if (count = 0) then
            count <= limit;
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
    if RST_I = '1' then
      state <= IDLE;
    else
      if (ENABLE_I = '1') then
        state <= next_state;
      end if;
    end if;
  end process FSM_CORE;

  -- FSM--------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  FSM : process (RST_I, START_I, VALID_I) is
  begin
    if (RST_I = '1') then
      state_next <= IDLE;
      VALID_O    <= '0';
      store      <= '0';
      run        <= '0';
    else
      state_next <= state;
      VALID_O    <= '0';
      store      <= '0';
      run        <= '0';
      case state is
        when IDLE =>
          if (START_I = '1') then
            run        <= '1';
            state_next <= RUNNING;
          end if;
        when RUNNING =>
          run <= '1';
          if (count = 0) then
            VALID_O <= '1';
            if (READY_I = '1') then
              state_next <= RUNNING;
            else
              run        <= '0';
              state_next <= DONE;
            end if;
          end if;
        when DONE =>
          VALID_O <= '1';
          if (READY_I = '1') then
            if (START_I = '1') then
              run        <= '1';
              state_next <= RUNNING;
            else
              state_next <= IDLE;
            end if;
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
