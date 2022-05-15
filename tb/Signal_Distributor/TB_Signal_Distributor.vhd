-------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_SIGNAL_DISTRIBUTOR - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Test Bench for Signal_Distributor.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

entity TB_SIGNAL_DISTRIBUTOR is
  --  Port ( );
end entity TB_SIGNAL_DISTRIBUTOR;

architecture TB of TB_SIGNAL_DISTRIBUTOR is

  constant CKTIME                                  : time := 10 ns;

  procedure assert_all_signals (
    constant val : std_logic;
    signal replic_i : in std_logic_vector
  ) is
  begin

    for i in replic_i'low to replic_i'high loop

      assert replic_i(i) = val
        report "Mismatch:: " &
               " i= " & integer'image(i) &
               " replic= " & integer'image(to_integer(unsigned(replic_i)));
    end loop;

  end procedure assert_all_signals;

  constant NUM_SIGNALS                             : integer := 14;
  constant MAX_FANOUT                              : integer := 3;
  constant S                                       : integer := integer(CEIL(LOG(REAL(NUM_SIGNALS), REAL(MAX_FANOUT))));
  signal   clk                                     : std_logic;
  signal   rst_i                                   : std_logic;
  signal   e_i                                     : std_logic;

  signal source                                    : std_logic;
  signal replic                                    : std_logic_vector(0 to NUM_SIGNALS - 1);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  SIGNAL_DISTRIBUTOR_1 : entity work.signal_distributor
    generic map (
      NUM_SIGNALS => NUM_SIGNALS,
      MAX_FANOUT  => MAX_FANOUT
    )
    port map (
      CLK    => clk,
      RST    => rst_i,
      E      => e_i,
      SOURCE => source,
      REPLIC => replic
    );

  TEST : process is

  begin

    rst_i <= '1';
    e_i   <= '0';
    source <= '0';
    wait for 3*CKTIME / 2;
    rst_i <= '0';
    e_i   <= '1';
    wait for CKTIME ;
    source <= '1';

    wait for (S+1)*CKTIME;

    assert_all_signals(val => '1', replic_i => replic);

    wait;

  end process TEST;

end architecture TB;
