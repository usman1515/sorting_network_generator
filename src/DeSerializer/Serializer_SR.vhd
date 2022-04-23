----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Serializer_SR - Structural
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

entity SERIALIZER_SR is
  generic (
    -- Number of values serialized in parallel.
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8
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
    SER_OUTPUT            : out   std_logic_vector(0 to N - 1)
  );
end entity SERIALIZER_SR;

architecture STRUCTURAL of SERIALIZER_SR is

begin

  LOADSHIFTREGISTERS : for i in 0 to N - 1 generate

    LOAD_SHIFT_REGISTER_1 : entity work.load_shift_register
      generic map (
        W => W
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
