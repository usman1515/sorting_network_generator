----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: RR_MUX_NxW - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Synchronous multiplexer with selection dependent on timer.
-- Multiplexes value from N x W-Bit inputs in round-robin fashion to W-bit
-- output.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity ROUNDROBIN_MUX is
  generic (
    -- Bit-width of each In-/output
    W : integer := 8;
    -- Number of Outputs.
    N : integer := 8
    );
  port (
    -- System clock.
    CLK_I    : in  std_logic;
    -- Enable.
    ENABLE_I : in  std_logic;
    -- Synchronous reset.
    RST_I    : in  std_logic;
    -- N x W-Bit input.
    DATA_I   : in  SLVArray(0 to N - 1)(W - 1 downto 0);
    -- W-Bit output.
    DATA_O   : out std_logic_vector(W - 1 downto 0)
    );
end entity ROUNDROBIN_MUX;

architecture BEHAVIORAL of ROUNDROBIN_MUX is

  signal count : integer range 0 to N - 1 := 0;

begin

  -- COUNTER---------------------------------------------------------------------
  -- Simple Counter with reset and enable.
  -------------------------------------------------------------------------------
  COUNTER : process(CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1' or count = N - 1) then
        count <= 0;
      else
        if (ENABLE_I = '1') then
          count <= count + 1;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- MUX-----------------------------------------------------------------------
  -- Synchronously multiplexes DATA_I to DATA_O with count as selection signal.
  -------------------------------------------------------------------------------
  MUX : process(CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      DATA_O <= DATA_I(count);
    end if;

  end process MUX;

end architecture BEHAVIORAL;
