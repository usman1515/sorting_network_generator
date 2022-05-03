----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_LFSR - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the LFSR with connecter Round-Robin DMUX and MUX.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_LFSR_RRDMUX_RRMUX is
  --  Port ( );
end entity TB_LFSR_RRDMUX_RRMUX;

architecture TB of TB_LFSR_RRDMUX_RRMUX is

  constant CKTIME        : time := 10 ns;
  constant W             : integer := 8;
  constant N             : integer := 8;
  constant POLY          : std_logic_vector(W - 1 downto 0) := "10111000";
  constant SEED          : std_logic_vector(W - 1 downto 0) := X"5A";

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal e_i             : std_logic;
  signal input_i         : std_logic_vector(W - 1 downto 0);
  signal inter_i         : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal output_i        : std_logic_vector(W - 1 downto 0);

  signal value_buffer    : SLVarray(0 to W)(W-1 downto 0);
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
      W    => W,
      POLY => POLY
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst,
      SEED   => SEED,
      OUTPUT => input_i
    );

  RR_DMUX_NXW_1 : entity work.rr_dmux_nxw
    generic map (
      W => W,
      N => N
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst,
      INPUT  => input_i,
      OUTPUT => inter_i
    );

  RR_MUX_NXW_1 : entity work.rr_mux_nxw
    generic map (
      W => W,
      N => N
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst,
      INPUT  => inter_i,
      OUTPUT => output_i
    );

  TEST_STIM : process is
  begin

    wait for CKTIME / 2;
    rst <= '1';
    e_i <= '0';
    wait for CKTIME / 2;
    e_i <= '1';
    rst <= '0';

    for j in 0 to 4 loop
      for i in 0 to W loop
        value_buffer(i) <= input_i;
        wait for CKTIME;
      end loop;
    end loop;

    wait;

  end process TEST_STIM;

  TEST_ASSER : process is
  begin
    wait for CKTIME;
    wait for CKTIME * W;

    for j in 0 to 4 loop
      for i in 0 to W loop
        wait for CKTIME;
        assert (value_buffer(i) = output_i)
          report "Mismatch:: " &
                " Input      = " & integer'image(to_integer(unsigned(value_buffer(i)))) &
                " Output     = " & integer'image(to_integer(unsigned(output_i))) &
                " Expectation= " & integer'image(to_integer(unsigned(value_buffer(i))));
      end loop;
    end loop;

    wait;

  end process TEST_ASSER;

end architecture TB;
