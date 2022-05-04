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
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                     : in    std_logic;
    -- Synchonous Reset
    RST                     : in    std_logic;
    -- Enable
    E                       : in    std_logic;
    -- Store signal
    STORE                   : in    std_logic;
    -- sub word parallel or bit serial input
    SER_INPUT               : in    SLVArray(0 to N - 1)(SW -1 downto 0);
    -- w-bit parallel output
    PAR_OUTPUT              : out   SLVArray(0 to N - 1)(W - 1 downto 0)
  );
end entity DESERIALIZERSW_SR;

architecture STRUCTURAL of DESERIALIZERSW_SR is

begin

  STORESHIFTREGISTERS : for i in 0 to N - 1 generate

    STORE_SHIFT_REGISTER_1 : entity work.store_shift_register_sw
      generic map (
        W => W,
        SW => SW
        )
      port map (
        CLK        => CLK,
        RST        => RST,
        E          => E,
        STORE      => STORE,
        SER_INPUT  => SER_INPUT(i),
        PAR_OUTPUT => PAR_OUTPUT(i)
      );

  end generate STORESHIFTREGISTERS;

end architecture STRUCTURAL;
