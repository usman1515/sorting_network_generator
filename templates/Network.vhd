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


entity {top_name} is
  generic (
    -- Bit-width of words
    W     : integer := {bit_width};
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
    -- Start signal marking the beginning of a new word.
    START         : in    std_logic;
    -- Serial input of the N input words.
    SER_INPUT     : in    std_logic_vector(0 to N - 1);
    -- Done signal, marking the end of sorting N words.
    DONE          : out   std_logic;
    -- Serial output of the M output words.
    SER_OUTPUT    : out   std_logic_vector(0 to M - 1)
  );
end entity {top_name};

architecture BEHAVIORAL of {top_name} is

  type wire_t is array (0 to N - 1) of std_logic_vector(0 to DEPTH-1);
  -- Wire grid with the dimensions of NxDepth
  signal wire     : wire_t;
  -- Start signal vector. Each bit corresponds to a stage of the network.
  signal start_i   : std_logic_vector(DEPTH downto 0);

begin

  start_i(start_i'low) <= START;
  DONE <= start_i(start_i'high);


  -- STARTDELAY------------------------------------------------------------------
  -- Generates a shift register for delaying the starting signal for each sorter
  -- stage.
  -------------------------------------------------------------------------------
  STARTDELAY : process(CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        start_i(start_i'high downto start_i'low + 1) <= (others => '0');
      else
        start_i(start_i'high downto start_i'low + 1) <= start_i(start_i'high - 1 downto start_i'low);
        end if;
    end if;

  end process STARTDELAY;

  {instances}

end architecture BEHAVIORAL;
