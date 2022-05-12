--------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_DSP_REGISTER - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the DSP_Register component.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_DSP_REGISTER is
end entity TB_DSP_REGISTER;

architecture TB of TB_DSP_REGISTER is

  constant CKTIME                       : time := 10 ns;

  constant NUM_INPUT                    : integer := 8;
  constant REG_PER_INPUT                : integer := 1;

  signal clk                            : std_logic;
  signal rst                            : std_logic;
  signal e_i                            : std_logic;

  signal lfsr                            : std_logic_vector(NUM_INPUT - 1 downto 0);
  signal dsp_in                          : std_logic_vector(NUM_INPUT - 1 downto 0);
  signal dsp0_out                        : std_logic_vector(NUM_INPUT - 1 downto 0);
  signal dsp1_out                        : std_logic_vector(NUM_INPUT - 1 downto 0);

  type wire_t is array (0 to 4 - 1) of std_logic_vector(0 to 4);

  signal wire      : wire_t;
begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  LFSR_1 : entity work.lfsr
    generic map (
      W    => NUM_INPUT - 2,
      POLY => "010101"
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst,
      SEED   => "011001",
      OUTPUT => lfsr(NUM_INPUT - 3 downto 0)
    );

  REGISTER_DSP_1 : entity work.register_dsp
    generic map (
      NUM_INPUT => NUM_INPUT
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      REG_INPUT  => dsp0_out(1 downto 0) & dsp_in(NUM_INPUT - 3 downto 0) ,
      REG_OUTPUT => dsp0_out
    );

  REGISTER_DSP_2 : entity work.register_dsp
    generic map (
      NUM_INPUT => NUM_INPUT
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      REG_INPUT(0)  => dsp_in(0),
      REG_INPUT(1)  => dsp_in(1),
      REG_INPUT(2)  => dsp_in(2),
      REG_INPUT(3)  => dsp_in(3),
      REG_INPUT(4)  => dsp_in(4),
      REG_INPUT(5)  => dsp_in(5),
      REG_INPUT(6)  => dsp1_out(5),
      REG_INPUT(7)  => dsp1_out(6),
      REG_OUTPUT(0) => dsp1_out(0),
      REG_OUTPUT(1) => dsp1_out(1),
      REG_OUTPUT(2) => dsp1_out(2),
      REG_OUTPUT(3) => dsp1_out(3),
      REG_OUTPUT(4) => dsp1_out(4),
      REG_OUTPUT(5) => dsp1_out(5),
      REG_OUTPUT(6) => dsp1_out(6),
      REG_OUTPUT(7) => dsp1_out(7)
    );

  wire(0)(0) <= dsp_in(0);
  wire(1)(0) <= dsp_in(1);
  wire(2)(0) <= dsp_in(2);
  wire(3)(0) <= dsp_in(3);

  FF_REPLACEMENT_0_GRP0 : entity work.register_dsp
    generic map (
      NUM_INPUT => 4,
      REG_PER_INPUT => 1

    )
    port map (
      CLK          => CLK,
      E            => '1',
      RST          => RST,
      REG_INPUT(0) => wire(0)(0),
      REG_INPUT(1) => wire(1)(0),
      REG_INPUT(2) => wire(2)(0),
      REG_INPUT(3) => wire(3)(0),

      REG_OUTPUT(0)  => wire(0)(3),
      REG_OUTPUT(1)  => wire(1)(3),
      REG_OUTPUT(2)  => wire(2)(3),
      REG_OUTPUT(3) => wire(3)(3)

    );

  TEST_STIM : process is
  begin
    dsp_in(NUM_INPUT -1 downto NUM_INPUT - 2) <= (others => '0');
    wait for CKTIME/2;
    rst <= '1';
    e_i <= '0';
    wait for CKTIME;
    rst <= '0';
    e_i <= '1';
    dsp_in <= (others => '0');
    wait for CKTIME*7;
    while (True) loop
      dsp_in <= lfsr;
      wait for CKTIME;
    end loop;

    wait;

  end process TEST_STIM;

  TEST_ASSERT : process is
  begin

    -- dsp <= (others => '0');
    -- wait for CKTIME;
    -- wait for (W) * CKTIME;
    -- deserialize(W, inter_dsp(0)(0), dsp);
    -- wait for CKTIME;
    -- assert_equal(dsp, reference);

    wait;

  end process TEST_ASSERT;

end architecture TB;
