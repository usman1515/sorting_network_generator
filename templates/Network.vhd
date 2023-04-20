----------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Sorting Network SW Template
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
  port (
    -- System clock
    CLK_I            : in    std_logic;
    -- Synchronous reset.
    RST_I            : in    std_logic;
    -- Enable Signal
    ENABLE_I         : in    std_logic;
    -- Start signal marking the beginning of a new word.
    START_I          : in    std_logic;
    -- Serial input of the N input words.
    DATA_I           : in    SLVArray(0 to {num_inputs} - 1)({subword_width} - 1 downto 0);
    -- Start output, marking the end of sorting N words.
    START_O          : out   std_logic_vector(0 to {num_start}-1);
    -- Feedback signal to indicate replication delay for START.
    START_FEEDBACK_O : out   std_logic;
    -- Enable output to indicate whether data output is valid
    ENABLE_O         : out   std_logic_vector(0 to {num_enable}-1);
    -- Feedback signal to indicate replication delay for ENABLE.
    ENABLE_FEEDBACK_O: out   std_logic;
    -- Serial output of the M output words.
    DATA_O           : out   SLVArray(0 to {num_outputs} - 1)({subword_width} - 1 downto 0)
  );
end entity {top_name};

architecture BEHAVIORAL of {top_name} is
  -- Number of input words.
  constant N          : integer := {num_inputs};
  -- Depth of network / number of stages.
  constant DEPTH      : integer := {net_depth};
  -- Number of sorted ouput words.
  constant M          : integer := {num_outputs};
   -- Width of words in bits
  constant W          : integer := {word_width};
  -- subword-width of serialization.
  constant SW         : integer := {subword_width};

{signal_definitions}

begin

{body}

end architecture BEHAVIORAL;
