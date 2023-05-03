
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Test_Sorter - STRUCTURAL
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

entity TEST_SORTER is
  port (
    -- Clock signal
    CLK_I      : in    std_logic;
    -- Synchronous Reset
    RST_I      : in    std_logic;
    -- Enable signal
    ENABLE_I   : in    std_logic;
    -- Bit indicating validity of received input sequence. '1' indicates total ordering of input
    -- sequence, '0' an order violation.
    IN_ORDER_O : out   std_logic
  );
end entity TEST_SORTER;

architecture STRUCTURAL of TEST_SORTER is

  -- Number of available BRAMs
  constant NUM_BRAM                     : integer := {num_bram};
  -- Bit-Width of words.
  constant W                            : integer := {word_width};
  -- Length of subwords, i.e. number of bits to be sorted at a time.
  constant SW                           : integer := {subword_width};
  -- Number of inputs
  constant N                            : integer := {num_inputs};
  -- Number of outputs
  constant M                            : integer := {num_outputs};

  -- Base values for LFSR generation.
  constant POLY_BASE                    : integer := 654;
  constant SEED_BASE                    : integer := 58;

  -- Busy signal used to control input value generation.
  signal input_control_busy             : std_logic;

  -- Enable signal for LFSRs.
  signal rng_enable                     : std_logic;
  -- Ready,Valid signals for network input.
  signal data_in_valid,  data_in_ready  : std_logic;
  -- Output of LFSRs, input of network
  signal data_unsorted                  : SLVArray(0 to N - 1)(W - 1 downto 0);
  -- Ready, Valid signals for network output.
  signal data_out_valid, data_out_ready : std_logic;
  -- Output of Sorting Network, input of validator
  signal data_sorted                    : SLVArray(0 to N - 1)(W - 1 downto 0);

begin

  INPUT : for i in 0 to N - 1 generate

    LFSR_1 : entity work.lfsr
      generic map (
        W => W,
        -- Attempt to create unique LFSR configuration to prevent consolidation at synthesis.
        POLY => std_logic_vector(to_unsigned(POLY_BASE + i, W))
      )
      port map (
        CLK_I    => CLK_I,
        ENABLE_I => rng_enable,
        RST_I    => RST_I,
        -- Same reason as with assignment of POLY.
        SEED_I => std_logic_vector(to_unsigned(SEED_BASE + i/2**W, W)),
        DATA_O => data_unsorted(i)
      );

  end generate INPUT;

  INPUT_CONTROL : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        input_control_busy <= '0';
      else
        if (input_control_busy = '0') then
          if (data_in_ready = '1' and data_in_valid = '1') then
            input_control_busy <= '1';
          end if;
        else
          input_control_busy <= '0';
        end if;
      end if;
    end if;

  end process INPUT_CONTROL;

  INPUT_CONTROL_COMB : process (RST_I, input_control_busy, data_in_ready) is
  begin

    if (RST_I = '1') then
      data_in_valid <= '0';
      rng_enable    <= '0';
    else
      if (input_control_busy = '0' and data_in_ready = '1') then
        data_in_valid <= '1';
        rng_enable    <= '1';
      else
        data_in_valid <= '0';
        rng_enable    <= '0';
      end if;
    end if;

  end process INPUT_CONTROL_COMB;

  SORTER_1 : entity work.sorter
    port map (
      CLK_I            => CLK_I,
      ENABLE_I         => ENABLE_I,
      RST_I            => RST_I,
      DATA_IN_READY_O  => data_in_ready,
      DATA_IN_VALID_I  => data_in_valid,
      DATA_I           => data_unsorted,
      DATA_OUT_READY_I => data_out_ready,
      DATA_OUT_VALID_O => data_out_valid,
      DATA_O           => data_sorted
    );

  VALIDATOR_1 : entity work.validator
    generic map (
      M  => M,
      W  => W,
      SW => SW
    )
    port map (
      CLK_I        => CLK_I,
      RST_I        => RST_I,
      ENABLE_I     => ENABLE_I,
      DATA_I       => data_sorted,
      DATA_VALID_I => data_out_valid,
      DATA_READY_O => data_out_ready,
      IN_ORDER_O   => IN_ORDER_O
    );

end architecture STRUCTURAL;
