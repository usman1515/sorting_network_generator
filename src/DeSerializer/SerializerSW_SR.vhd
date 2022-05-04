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
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                   : in    std_logic;
    -- Synchonous Reset
    RST                   : in    std_logic;
    -- Enable
    E                     : in    std_logic;
    -- Load signal
    LOAD                  : in    std_logic;
    -- w-bit parallel input
    PAR_INPUT             : in    SLVArray(0 to N - 1)(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   SLVArray(0 to N - 1)(SW - 1 downto 0)
  );
end entity SERIALIZERSW_SR;

architecture STRUCTURAL of SERIALIZERSW_SR is

begin

  LOADSHIFTREGISTERS : for i in 0 to N - 1 generate

    LOAD_SHIFT_REGISTER_1 : entity work.load_shift_register_sw
      generic map (
        W => W,
        SW => SW
      )
      port map (
        CLK        => CLK,
        RST        => RST,
        E          => E,
        LOAD       => LOAD,
        PAR_INPUT  => PAR_INPUT(i),
        SER_OUTPUT => SER_OUTPUT(i)
      );

  end generate LOADSHIFTREGISTERS;

end architecture STRUCTURAL;
