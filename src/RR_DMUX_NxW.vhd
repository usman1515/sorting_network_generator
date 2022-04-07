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

entity RR_DMUX_NXW is
  generic (
    -- Bit-width of each In-/output
    W : integer := 8;
    -- Number of Outputs.
    N : integer := 8
  );
  port (
    -- System clock.
    CLK      : in    std_logic;
    -- Enable.
    E        : in    std_logic;
    -- Synchronous reset.
    RST      : in    std_logic;
    -- W-Bit input.
    INPUT    : in    std_logic_vector(W - 1 downto 0);
    -- N x W-Bit output.
    OUTPUT   : out   SLVArray(N - 1 downto 0)(W - 1 downto 0)
  );
end entity RR_DMUX_NXW;

architecture BEHAVIORAL of RR_DMUX_NXW is

  signal count : integer range 0 to N - 1;

begin

  -- COUNTER---------------------------------------------------------------------
  -- Simple Counter with reset and enable.
  -------------------------------------------------------------------------------
  COUNTER : process is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or count = N - 1) then
        count <= 0;
      else
        if (E = '1') then
          count <= count + 1;
        end if;
      end if;
    end if;

  end process COUNTER;

  -- DEMUX-----------------------------------------------------------------------
  -- Synchronously demultiplexes INPUT to OUTPUT with count as selection signal.
  -------------------------------------------------------------------------------
  DEMUX : process is
  begin

    if rising_edge(CLK) then
      if (RST = '1') then
        OUTPUT <= (others => (others => '0'));
      else
        OUTPUT(count) <= INPUT;
      end if;
    end if;

  end process DEMUX;

end architecture BEHAVIORAL;
