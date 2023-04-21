-------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Test_Sorter_X - STRUCTURAL
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Connects components to form a test sorting network with pseudo
-- random number generation as input. Can be changed to use arbitrary sorting network.
--
----------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity TEST_SORTER_X is
  generic (
    -- Bit-Width of input values.
    W        : integer := 8;
    -- Length of subwords.
    SW       : integer := 1;
    -- Number of available BRAMs
    NUM_BRAM : integer := 4318
    );
  port (
    -- Clock signal
    CLK_I      : in  std_logic;
    -- Synchronous Reset
    RST_I      : in  std_logic;
    -- Enable signal
    ENABLE_I   : in  std_logic;
    -- Bit indicating validity of received input sequence. '1' indicates total ordering of input
    -- sequence, '0' an order violation.
    IN_ORDER_O : out std_logic
    );
end entity TEST_SORTER_X;

architecture STRUCTURAL of TEST_SORTER_X is

  constant N         : integer := 8;
  constant DEPTH     : integer := 6;
  constant POLY_BASE : integer := 654;
  constant SEED_BASE : integer := 58;
  constant ceilWSW   : integer := ((W + SW - 1) / SW);


  signal enable_delayed : std_logic_vector(1 downto 0);
  -- Output of LFSRs
  signal data_random    : SLVArray(0 to N / ceilWSW)(W - 1 downto 0);
  -- Output of Round-Robin DMUXs
  signal data_unsorted  : SLVArray(0 to N - 1)(W - 1 downto 0);
  -- Output of Sorting Network
  signal data_sorted    : SLVArray(0 to N - 1)(W - 1 downto 0);
  -- Since open outputs are disallowed...
  signal unused         : SLVArray(0 to W - 1 - N rem W)(W - 1 downto 0);

  signal data_in_valid, data_in_ready : std_logic;
  signal data_counter                 : integer range 0 to ceilWSW;
  signal rng_enable                   : std_logic;

  signal data_out_valid, data_out_ready : std_logic;
  signal validator_enable               : std_logic;
begin

  INPUT : for i in 0 to N / ceilWSW - 1 generate

    LFSR_1 : entity work.lfsr
      generic map (
        W    => W,
        -- Attempt to create unique LFSR configuration to prevent consolidation at synthesis.
        POLY => std_logic_vector(to_unsigned(POLY_BASE + i, W))
        )
      port map (
        CLK_I    => CLK_I,
        ENABLE_I => ENABLE_I,
        RST_I    => RST_I,
        -- Same reason as with assignment of POLY.
        SEED_I   => std_logic_vector(to_unsigned(SEED_BASE + i/2**W, W)),
        DATA_O   => data_random(i)
        );

    ROUNDROBIN_DMUX_DIV : entity work.ROUNDROBIN_DMUX
      generic map (
        W => W,
        N => ceilWSW
        )
      port map (
        CLK_I    => CLK_I,
        ENABLE_I => ENABLE_I,
        RST_I    => RST_I,
        DATA_I   => data_random(i),
        DATA_O   => data_unsorted(i*ceilWSW to (i + 1)*ceilWSW - 1)
        );

  end generate INPUT;

  INPUT_REM : if (N rem ceilWSW /= 0) generate

    LFSR_REM : entity work.lfsr
      generic map (
        W    => W,
        POLY => std_logic_vector(to_unsigned(POLY_BASE + N/W, W))
        )
      port map (
        CLK_I    => CLK_I,
        ENABLE_I => ENABLE_I,
        RST_I    => RST_I,
        SEED_I   => std_logic_vector(to_unsigned(SEED_BASE + N/W/W, W)),
        DATA_O   => data_random(N/ceilWSW)
        );

    ROUNDROBIN_DMUX_REM : entity work.ROUNDROBIN_DMUX
      generic map (
        W => W,
        N => N mod ceilWSW
        )
      port map (
        CLK_I    => CLK_I,
        ENABLE_I => ENABLE_I,
        RST_I    => RST_I,
        DATA_I   => data_random(N/ceilWSW),
        DATA_O   => data_unsorted(N - N mod ceilWSW to N -1)
        );

  end generate INPUT_REM;



  rng_timer : process (CLK_I) is
  begin
    if (RST_I = '1') then
      data_counter  <= ceilWSW-1;
      rng_enable    <= '0';
      data_in_valid <= '0';
    else
      if (ENABLE_I = '1') then
        rng_enable <= '1';
        if (data_counter = 0) then
          rng_enable    <= '0';
          data_in_valid <= '1';
          if(data_in_ready = '1') then
            rng_enable   <= '1';
            data_counter <= ceilWSW - 1;
          end if;
        else
          data_counter <= data_counter - 1;
        end if;
      end if;
    end if;
  end process rng_timer;

  SORTER_1 : entity work.SORTER
    generic map (
      W        => W,
      SW       => SW,
      N        => N,
      M        => M,
      NUM_BRAM => NUM_BRAM)
    port map (
      CLK_I            => CLK_I,
      ENABLE_I         => ENABLE_I,
      RST_I            => RST_I,
      DATA_IN_READY_O  => data_in_ready,
      DATA_IN_VALID_I  => data_in_valid,
      DATA_I           => data_unsorted,
      DATA_OUT_READY_I => '1',
      DATA_OUT_VALID_O => data_out_valid,
      DATA_O           => data_sorted);



  VALIDATOR_1 : entity work.validator
    generic map (
      N  => N,
      SW => SW
      )
    port map (
      CLK_I      => CLK_I,
      ENABLE_I   => data_out_valid,
      RST_I      => RST_I,
      DATA_I     => data_sorted,
      IN_ORDER_O => IN_ORDER_O
      );

end architecture STRUCTURAL;
