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
    -- Load signal
    LOAD_I   : in  std_logic;
    -- w-bit parallel input
    DATA_I   : in  SLVArray(0 to N - 1)(W - 1 downto 0);
    -- bit-serial output
    STREAM_O : out SLVArray(0 to N - 1)(SW - 1 downto 0)
    );
end entity SERIALIZERSW_SR;

architecture STRUCTURAL of SERIALIZERSW_SR is

begin

  LOADSHIFTREGISTERS : for i in 0 to N - 1 generate

    LOAD_SHIFT_REGISTER_1 : entity work.load_shift_register
      generic map (
        W  => W,
        SW => SW
        )
      port map (
        CLK_I    => CLK_I,
        RST_I    => RST_I,
        ENABLE_I => ENABLE_I,
        LOAD_I   => LOAD_I,
        DATA_I   => DATA_I(i),
        STREAM_O => STREAM_O(i)
        );

  end generate LOADSHIFTREGISTERS;

end architecture STRUCTURAL;
