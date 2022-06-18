-------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Deserializer_BRAM - Structural
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Deserializer for N W-bit values in parallel. Uses Store Shift Registers.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.MATH_REAL.all;

library work;
  use work.CustomTypes.all;

entity DESERIALIZER_BRAM is
  generic (
    -- Number of values serialized in parallel.
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8;
    -- width of subwords processed at a time
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
    -- bit-serial output
    PAR_OUTPUT              : out   SLVArray(0 to N - 1)(W - 1 downto 0)
  );
end entity DESERIALIZER_BRAM;

architecture STRUCTURAL of DESERIALIZER_BRAM is

  constant WADDR_WIDTH     : integer := integer(ceil(log2(real(W))));
  signal waddr             : integer range 0 to W - 1;
  signal slv_waddr         : std_logic_vector(WADDR_WIDTH - 1 downto 0);

  signal ser_input_i      : SLVArray(0 to N -1)(0 downto 0);

begin

  SET_SLV_WADDR : process(waddr) is
  begin

    slv_waddr <= std_logic_vector(to_unsigned(waddr, WADDR_WIDTH));

  end process SET_SLV_WADDR;

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or STORE = '1') then
        waddr <= (W + SW - 1)/SW -1;
      else
        if (E = '1') then
          if (waddr = 0) then
            waddr <= (W + SW - 1)/SW - 1;
          else
            waddr <= waddr - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  STORESHIFTREGISTERS : for i in 0 to N - 1 generate

    STORE_SHIFT_REGISTER_1 : entity work.store_shift_register_BRAM
      generic map (
        W => W,
        SW => SW
      )
      port map (
        CLK        => CLK,
        RST        => RST,
        E          => E,
        STORE      => STORE,
        WADDR      => slv_waddr,
        SER_INPUT  => SER_INPUT(i),
        PAR_OUTPUT => PAR_OUTPUT(i)
      );

  end generate STORESHIFTREGISTERS;

end architecture STRUCTURAL;
