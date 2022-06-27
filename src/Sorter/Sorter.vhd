------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Sorter
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity SORTER is
  generic (
    -- Bit-width of words
    W      : integer := 8;
    -- Bit-width of subwords
    SW     : integer := 1;
    -- Number of input words.
    N      : integer := 704;
    -- Number of sorted ouput words.
    M      : integer := 704;
    -- Number of available BRAMs
    NUM_BRAM : integer := 4318
  );
  port (
    -- System clock
    CLK          : in    std_logic;
    -- Enable signal
    E            : in    std_logic;
    -- Syncronous reset
    RST          : in    std_logic;
    -- Parallel input of N unsorted w-bit words.
    PAR_INPUT    : in    SLVArray(0 to N - 1)(W - 1 downto 0);
    -- Parallel ouput of N sorted w-bit words.
    PAR_OUTPUT   : out   SLVArray(0 to M - 1)(W - 1 downto 0)
  );
end entity SORTER;

architecture STRUCTURAL of SORTER is

  -- Number of BRAM blocks required per IO.
  constant BRAM_PER_IO : integer := (W + 32 - 1) / 32;
  -- Number of available IO ports replacable with BRAM version.
  constant NUM_IO_BRAM : integer := NUM_BRAM / BRAM_PER_IO;
  -- Number of remaining BRAMS for output deserialization.
  constant NUM_OUTPUT_BRAM : integer := NUM_IO_BRAM - N;


  -- Start signal generated by cycle timer.
  signal start_i         : std_logic;
  -- Done signal generated by the sorting network.
  signal done_i          : std_logic;
  -- Serial unsorted data.
  signal ser_unsorted_i  : SLVArray(0 to N - 1)(SW - 1 downto 0);
  -- Serial sorted data.
  signal ser_sorted_i    : SLVArray(0 to M - 1)(SW - 1 downto 0);

begin

  CYCLE_TIMER_1 : entity work.cycle_timer
    generic map (
      W  => W,
      SW => SW,
      DELAY => 0
    )
    port map (
      CLK   => CLK,
      RST   => RST,
      E     => E,
      START => start_i
    );

  SERIALIZERSW_SR_2 : entity work.serializersw_sr
    generic map (
      N  => N,
      W  => W,
      SW => SW
    )
    port map (
      CLK        => CLK,
      RST        => RST,
      E          => E,
      LOAD       => start_i,
      PAR_INPUT  => PAR_INPUT,
      SER_OUTPUT => ser_unsorted_i
    );

  SORTING_NETWORK_1 : entity work.oddeven_4_to_4_max
    generic map (
      -- Bit-width of words
      W => W
    )
    port map (
      CLK        => CLK,
      RST        => RST,
      E          => E,
      START      => start_i,
      SER_INPUT  => ser_unsorted_i,
      DONE       => done_i,
      SER_OUTPUT => ser_sorted_i
    );

  DESERIALIZERSW_SR_1 : entity work.deserializersw_sr
    generic map (
      N  => M,
      W  => W,
      SW => SW
    )
    port map (
      CLK        => CLK,
      RST        => RST,
      E          => E,
      STORE      => done_i,
      SER_INPUT  => ser_sorted_i,
      PAR_OUTPUT => PAR_OUTPUT
    );

end architecture STRUCTURAL;
