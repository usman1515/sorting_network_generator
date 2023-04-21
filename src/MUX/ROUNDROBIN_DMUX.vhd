----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: RR_DMUX_NxW - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Synchronous demultiplexer with selection dependent on timer.
-- Distributes value from W-Bit input in round-robin fashion to N x W-bit
-- outputs.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity ROUNDROBIN_DMUX is
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
    -- W-Bit input.
    DATA_I   : in  std_logic_vector(W - 1 downto 0);
    -- N x W-Bit output.
    DATA_O   : out SLVArray(0 to N - 1)(W - 1 downto 0)
    );
end entity ROUNDROBIN_DMUX;

architecture BEHAVIORAL of ROUNDROBIN_DMUX is

  signal count : integer range 0 to N - 1;

begin

  -- COUNTER---------------------------------------------------------------------
  -- Simple Counter with reset and enable.
  -------------------------------------------------------------------------------
  COUNTER : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      -- If N = 1 there is nothing to distribute and therfore no need for the timer.
      if (N > 1) then
        if (RST_I = '1' or count = N - 1) then
          count <= 0;
        else
          if (ENABLE_I = '1') then
            count <= count + 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- DEMUX-----------------------------------------------------------------------
  -- Synchronously demultiplexes DATA_I to DATA_O with count as selection signal.
  -------------------------------------------------------------------------------
  DEMUX : process (CLK_I) is
  begin

    if rising_edge(CLK_I) then
      if (RST_I = '1') then
        DATA_O <= (others => (others => '0'));
      else
        -- Similarily, the DATA_O becomes independent of the timer if N = 1.
        if (N > 1) then
          DATA_O(count) <= DATA_I;
        else
          DATA_O(0) <= DATA_I;
        end if;
      end if;
    end if;

  end process DEMUX;

end architecture BEHAVIORAL;
