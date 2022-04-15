----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_LFSR - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the linear feedback shift register.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;

  -- Uncomment the following library declaration if using
  -- arithmetic functions with Signed or Unsigned values
  use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity TB_LFSR is
  --  Port ( );
end entity TB_LFSR;

architecture TB of TB_LFSR is

  constant CKTIME     : time := 10 ns;
  constant W          : integer := 8;
  constant P          : std_logic_vector(W - 1 downto 0) := "10111000";

  signal clk          : std_logic;
  signal rst_i        : std_logic;
  signal e_i          : std_logic;
  signal seed_i       : std_logic_vector(W - 1 downto 0);
  signal output_i     : std_logic_vector(W - 1 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  LSFR_1 : entity work.lfsr
    generic map (
      W => W,
      P => P
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      SEED   => seed_i,
      OUTPUT => output_i
    );

  TEST_PROCESS : process is

  begin

    seed_i <= X"8A";
    wait for CKTIME / 2;
    rst_i  <= '1';
    e_i    <= '0';
    wait for CKTIME / 2;
    e_i    <= '1';
    rst_i  <= '0';
    wait for 16 * CKTIME / 2;

    wait;

  end process TEST_PROCESS;

end architecture TB;
