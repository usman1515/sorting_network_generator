----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Sorter_Top - STRUCTURAL
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Top module for implementation of a Test Sorter on Zedboard Rev. C
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TEST_SORTER_TOP is
  port (
    SYSCLK : in    std_logic;
    GPIO_DIP_SW1   : in    std_logic_vector(0 downto 0);
    GPIO_SW_C : in    std_logic_vector(0 downto 0);
    GPIO_LED0   : out   std_logic_vector(0 downto 0)
  );
end entity TEST_SORTER_TOP;

architecture STRUCTURAL of TEST_SORTER_TOP is

  constant W : integer := 64;
  -- Number of 18kB BRAM blocks available.
  constant NUM_BRAM : integer := 4318;
  -- Debounced reset signal.
  signal r_i : std_logic;
  -- Debounced enable signal.
  signal e_i : std_logic;

begin

  RESETDEBOUNCER : entity work.DEBOUNCER
    generic map (
      TIMEOUT_CYCLES => 50
    )
    port map (
      CLK    => SYSCLK,
      RST    => '0',
      INPUT  => GPIO_SW_C(0),
      OUTPUT => r_i
    );

  ENABLEDEBOUNCER : entity work.DEBOUNCER
    generic map (
      TIMEOUT_CYCLES => 50
    )
    port map (
      CLK    => SYSCLK,
      RST    => '0',
      INPUT  => GPIO_DIP_SW1(0),
      OUTPUT => e_i
    );

  TEST_SORTER_X_1 : entity work.test_sorter_X
    generic map (
      W => W
    )
    port map (
      CLK   => SYSCLK,
      RST   => r_i,
      E     => e_i,
      VALID => GPIO_LED0(0)
    );

end architecture STRUCTURAL;
