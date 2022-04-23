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
    GCLK : in    std_logic;
    SW   : in    std_logic_vector(0 downto 0);
    BTNC : in    std_logic;
    LD   : out   std_logic_vector(0 downto 0)
  );
end entity TEST_SORTER_TOP;

architecture STRUCTURAL of TEST_SORTER_TOP is

  constant W : integer := 8;

  signal r_i : std_logic; -- Debounced reset signal.
  signal e_i : std_logic; -- Debounced enable signal.

begin

  RESETDEBOUNCER : entity work.DEBOUNCER
    generic map (
      TIMEOUT_CYCLES => 50
    )
    port map (
      CLK    => GCLK,
      RST    => '0',
      INPUT  => BTNC,
      OUTPUT => r_i
    );

  ENABLEDEBOUNCER : entity work.DEBOUNCER
    generic map (
      TIMEOUT_CYCLES => 50
    )
    port map (
      CLK    => GCLK,
      RST    => '0',
      INPUT  => SW(0),
      OUTPUT => e_i
    );

  TEST_SORTER_X_1 : entity work.test_sorter_X
    generic map (
      W => W
    )
    port map (
      CLK   => GCLK,
      RST   => r_i,
      E     => e_i,
      VALID => LD(0)
    );

end architecture STRUCTURAL;
