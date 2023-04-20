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
    -- Store signal
    STORE_I  : in  std_logic;
    -- sub word parallel or bit serial input
    STREAM_I : in  SLVArray(0 to N - 1)(SW -1 downto 0);
    -- w-bit parallel output
    DATA_O   : out SLVArray(0 to N - 1)(W - 1 downto 0)
    );
end entity DESERIALIZERSW_SR;

architecture STRUCTURAL of DESERIALIZERSW_SR is

begin

  STORESHIFTREGISTERS : for i in 0 to N - 1 generate

    STORE_SHIFT_REGISTER_1 : entity work.store_shift_register
      generic map (
        W  => W,
        SW => SW
        )
      port map (
        CLK_I    => CLK_I,
        RST_I    => RST_I,
        ENABLE_I => ENABLE_I,
        STORE_I  => STORE_I,
        STREAM_I => STREAM_I(i),
        DATA_O   => DATA_O(i)
        );

  end generate STORESHIFTREGISTERS;

end architecture STRUCTURAL;
