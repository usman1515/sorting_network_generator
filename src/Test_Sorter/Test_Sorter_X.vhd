----------------------------------------------------------------------------------
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
    W : integer := 8
  );
  port (
    -- Clock signal
    CLK     : in    std_logic;
    -- Synchronous Reset
    RST     : in    std_logic;
    -- Enable signal
    E       : in    std_logic;
    -- Bit indicating validity of received input sequence. '1' indicates total ordering of input
    -- sequence, '0' an order violation.
    VALID   : out   std_logic
  );
end entity TEST_SORTER_X;

architecture STRUCTURAL of TEST_SORTER_X is

  constant N             : integer := 4;
  constant DEPTH         : integer := 3;
  constant POLY_BASE     : integer := 654;
  constant SEED_BASE     : integer := 58;

  signal e_delayed_i     : std_logic_vector(1 downto 0) := (others => '0');
  -- Output of LFSRs
  signal rand_data_i     : SLVArray(0 to N / W)(W - 1 downto 0) := (others => (others => '0'));
  -- Output of Round-Robin DMUXs
  signal unsorted_data_i : SLVArray(0 to N - 1)(W - 1 downto 0) := (others => (others => '0'));
  -- Output of Sorting Network
  signal sorted_data_i   : SLVArray(0 to N - 1)(W - 1 downto 0) := (others => (others => '0'));
  -- Since open outputs are disallowed...
  signal unused_i        : SLVArray(0 to W - 1 - N rem W)(W - 1 downto 0);

begin

  INPUT : for i in 0 to N / W - 1 generate

    LFSR_1 : entity work.lfsr
      generic map (
        W => W,
        -- Attempt to create unique LFSR configuration to prevent consolidation at synthesis.
        POLY => std_logic_vector(to_unsigned(POLY_BASE + i,W))
      )
      port map (
        CLK => CLK,
        E   => E,
        RST => RST,
        -- Same reason as with assignment of POLY.
        SEED   => std_logic_vector(to_unsigned(SEED_BASE + i/2**W ,W)),
        OUTPUT => rand_data_i(i)
      );

    RR_DMUX_NXW_REM : entity work.rr_dmux_nxw
      generic map (
        W => W,
        N => W
      )
      port map (
        CLK    => CLK,
        E      => E,
        RST    => RST,
        INPUT  => rand_data_i(i),
        OUTPUT => unsorted_data_i(i*W to (i + 1)*W - 1)
      );

  end generate INPUT;

  INPUT_REM : if (N rem W /= 0) generate

    LFSR_REM : entity work.lfsr
      generic map (
        W    => W,
        POLY => std_logic_vector(to_unsigned(POLY_BASE + N/W,W))
      )
      port map (
        CLK    => CLK,
        E      => E,
        RST    => RST,
        SEED   => std_logic_vector(to_unsigned(SEED_BASE + N/W/2**W,W)),
        OUTPUT => rand_data_i(N/W)
      );

    RR_DMUX_NXW_REM : entity work.rr_dmux_nxw
      generic map (
        W => W,
        N => W
      )
      port map (
        CLK                      => CLK,
        E                        => E,
        RST                      => RST,
        INPUT                    => rand_data_i(N/W),
        OUTPUT(0 to N rem W - 1) => unsorted_data_i((N/W)*W to N - 1),
        OUTPUT(N rem W to W - 1) => unused_i(0 to W - 1 - N rem W)
      );

  end generate INPUT_REM;

  ENABLEDELAY_1 : entity work.delay_timer
    generic map (
      DELAY => W - 1
    )
    port map (
      CLK       => CLK,
      E         => not RST,
      RST       => RST,
      A         => E,
      A_DELAYED => e_delayed_i(0)
    );

  SORTER_1 : entity work.sorter
    generic map (
      W => W,
      N => N,
      M => N
    )
    port map (
      CLK        => CLK,
      E          => E,
      RST        => RST,
      PAR_INPUT  => unsorted_data_i,
      PAR_OUTPUT => sorted_data_i
    );

  ENABLEDELAY_2 : entity work.delay_timer
    generic map (
      -- Delay: serialization cost + network depth + store delay.
      DELAY => W + DEPTH + 2
    )
    port map (
      CLK       => CLK,
      E         => not RST,
      RST       => RST,
      A         => e_delayed_i(0),
      A_DELAYED => e_delayed_i(1)
    );

  VALIDATOR_1 : entity work.validator
    generic map (
      W => W,
      N => N
    )
    port map (
      CLK   => CLK,
      E     => e_delayed_i(1),
      RST   => RST,
      INPUT => sorted_data_i,
      VALID => VALID
    );

end architecture STRUCTURAL;
