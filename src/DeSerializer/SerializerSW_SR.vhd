----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SerializerSW_SR - Structural
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Serializer for N W-bit values in parallel. Uses Load Shift Registers.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity SERIALIZERSW_SR is
  generic (
    -- Number of values serialized in parallel.
    N  : integer;
    -- Width of parallel input/ word.
    W  : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
    );
  port (
    -- System Clock
    CLK_I    : in  std_logic;
    -- Synchonous Reset
    RST_I    : in  std_logic;
    -- Enable
    ENABLE_I : in  std_logic;
    -- Start signal to indicate beginning of serialization.
    START_I  : in  std_logic;
    -- Data valid signal
    VALID_I  : in  std_logic;
    -- Data ready signal
    READY_O  : out std_logic;
    -- w-bit parallel input
    DATA_I   : in  SLVArray(0 to N - 1)(W - 1 downto 0);
    -- bit-serial output
    STREAM_O : out SLVArray(0 to N - 1)(SW - 1 downto 0)
    );
end entity SERIALIZERSW_SR;

architecture STRUCTURAL of SERIALIZERSW_SR is

  type state_t is (IDLE, STARTUP, RUNNING);
  signal state, next_state : state_t;

  constant limit : integer := ((W+SW-1)/SW) - 1;
  signal count   : integer range 0 to limit;

  signal load, run : std_logic;
begin

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
        if (state = RUNNING) then
          if (count > 0) then
            count <= count - 1;
          end if;
        else
          count <= limit;
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
  -- State machine consisting of the three states IDLE, RUNNING and valid.
  -- IDLE is the default state, positive valid will bring the state to STARTUP.
  -- In STARTUP, FSM waits on a START pulse to transition into RUNNING state.
  -- In RUNNING state, serialization progresses and is done when count reaches
  -- zero. The next state may either be IDLE, if VALID is zero, or STARTUP
  -- again, if VALID is positive.
  --------------------------------------------------------------------------------
  FSM : process (RST_I, START_I, VALID_I) is
  begin
    if (RST_I = '1') then
      state_next <= IDLE;
      READY_O    <= '0';
      load       <= '0';
      run        <= '0';
    else
      state_next <= state;
      READY_O    <= '0';
      load       <= '0';
      run        <= '0';
      case state is
        when IDLE =>
          READY_O <= '1';
          if (VALID_I = '1') then
            load       <= '1';
            state_next <= STARTUP;
          end if;
        when STARTUP =>
          if (START_I = '1') then
            state_next <= RUNNING;
            run        <= '1';
          end if;
        when RUNNING =>
          run <= '1';
          if (count = 0) then
            READY_O <= '1';
            if (VALID_I = '1') then
              load       <= '1';
              state_next <= STARTUP;
            else
              state_next <= IDLE;
            end if;
          end if;
      end case;
    end if;
  end process FSM;

  LOADSHIFTREGISTERS : for i in 0 to N - 1 generate

    LOAD_SHIFT_REGISTER_1 : entity work.load_shift_register
      generic map (
        W  => W,
        SW => SW
        )
      port map (
        CLK_I    => CLK_I,
        RST_I    => RST_I,
        RUN_I => run,
        LOAD_I   => load,
        DATA_I   => DATA_I(i),
        STREAM_O => STREAM_O(i)
        );

  end generate LOADSHIFTREGISTERS;

end architecture STRUCTURAL;
