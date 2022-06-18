----------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Sorting Network Template
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
library work;
  use work.CustomTypes.all;

entity {top_name} is
  generic (
    -- Bit-width of words
    W     : integer := {bit_width};
    -- subword-width of serialization.
    SW     : integer := {subword_width};
    -- Depth of network / number of stages.
    DEPTH : integer := {net_depth};
    -- Number of input words.
    N     : integer := {num_inputs};
    -- Number of sorted ouput words.
    M     : integer := {num_outputs}
  );
  port (
    -- System clock
    CLK           : in    std_logic;
    -- Synchronous reset.
    RST           : in    std_logic;
    -- Enable Signal
    E             : in    std_logic;
    -- Start signal marking the beginning of a new word.
    START         : in    std_logic;
    -- Serial input of the N input words.
    SER_INPUT     : in    SLVArray(0 to N - 1)(SW - 1 downto 0);
    -- Done signal, marking the end of sorting N words.
    DONE          : out   std_logic;
    -- Serial output of the M output words.
    SER_OUTPUT    : out   SLVArray(0 to M - 1)(SW - 1 downto 0)
  );
end entity {top_name};

architecture BEHAVIORAL of {top_name} is

  {control_signal_definition}

  type wire_subtype_t is array (0 to DEPTH) of std_logic_vector(SW -1 downto 0);
  type wire_t is array (0 to N - 1) of wire_subtype_t;
  -- Wire grid with the dimensions of NxDepth
  signal wire     : wire_t := (others => (others => '0'));


begin

  SHIFT_REGISTER_DONE: entity work.SHIFT_REGISTER
    generic map (
      W => W + DEPTH)
    port map (
      CLK        => CLK,
      RST        => RST,
      E          => E,
      SER_INPUT  => START,
      SER_OUTPUT => DONE);

  {control_signal_distribution}


  {instances}

end architecture BEHAVIORAL;
