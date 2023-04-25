----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: LFSR - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Linear Feedback Shift register for generation of pseudo random
-- numbers.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity LFSR is
  generic (
    -- Bit-width of LFSR
    W    : integer := 8;
    -- Generator Polynomial
    POLY : std_logic_vector
    );
  port (
    -- System Clock
    CLK_I    : in  std_logic;
    -- Enable
    ENABLE_I : in  std_logic;
    -- Reset
    RST_I    : in  std_logic;
    -- Seed for pseudo-random number generation
    SEED_I   : in  std_logic_vector(W - 1 downto 0);
    -- W-Bit output.
    DATA_O : out std_logic_vector(W - 1 downto 0)
    );
end entity LFSR;

architecture BEHAVIORAL of LFSR is

  signal reg  : std_logic_vector(W - 1 downto 0);
  signal mask : std_logic_vector(W - 1 downto 0);

begin

  DATA_O <= reg;
  -- GENMASK----------------------------------------------------------------------
  -- Generates mask value from generator polynomial and LSB of reg.
  --------------------------------------------------------------------------------
  GENMASK : process (reg(reg'low)) is
  begin

    for i in mask'low to mask'high loop

      mask(i) <= POLY(i) and reg(reg'low);

    end loop;

  end process GENMASK;

  -- MAIN-------------------------------------------------------------------------
  -- On reset, fills reg with value of seed_I otherwise applies XOR of reg and high
  -- to reg.
  --------------------------------------------------------------------------------
  MAIN : process(CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        reg <= SEED_I;
      else
        if (ENABLE_I = '1') then
          reg <= '0' & reg(reg'high downto reg'low + 1) xor mask;
        end if;
      end if;
    end if;

  end process MAIN;

end architecture BEHAVIORAL;
