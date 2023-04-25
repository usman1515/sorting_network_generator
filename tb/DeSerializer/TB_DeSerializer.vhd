----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_DeSerializer - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for the batch DeSerialzers.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_DESERIALIZER is
  --  Port ( );
end entity TB_DESERIALIZER;

architecture TB of TB_DESERIALIZER is

  constant CLK_PERIOD              : time := 10 ns;

  procedure load_and_store (
    constant W        : integer;
    constant SW       : integer;
    constant value    : SLVArray;
    signal input      : out  SLVArray;
    signal ser_ready  : in  std_logic;
    signal ser_valid  : out  std_logic;
    signal dser_ready : out  std_logic;
    signal dser_valid : in  std_logic
  ) is
  begin

    input      <= (others => (others => '0'));
    ser_valid  <= '0';
    dser_ready <= '0';

    while (ser_ready = '0') loop

      ser_valid <= '0';
      wait for CLK_PERIOD;

    end loop;

    ser_valid <= '1';
    input     <= value;
    wait for CLK_PERIOD;
    input     <= (others => (others => '0'));
    ser_valid <= '0';
    -- wait for ceil(W/SW) - 1
    wait for ((W + SW - 1) / SW - 1) * CLK_PERIOD;

    while (dser_valid = '0') loop

      dser_ready <= '0';
      wait for CLK_PERIOD;

    end loop;

    dser_ready <= '1';
    wait for CLK_PERIOD;
    dser_ready <= '0';

  end procedure load_and_store;

  procedure assert_equivalence (
    constant N    : integer;
    signal input  : in  SLVArray;
    signal output : in  SLVArray
  ) is
  begin

    for i in 0 to N - 1 loop

      assert (input(i) = output(i))
        report "Mismatch:: " &
               " Input      = " & integer'image(to_integer(unsigned(input(i)))) &
               " Output     = " & integer'image(to_integer(unsigned(output(i)))) &
               " Expectation= " & integer'image(to_integer(unsigned(input(i))));

    end loop;

  end procedure assert_equivalence;

  constant W                       : integer := 8;
  constant N                       : integer := 4;
  constant SW                      : integer := 1;

  signal clk                       : std_logic;
  signal rst                       : std_logic;
  signal enable                    : std_logic;

  signal start,start_delayed                     : std_logic;

  signal s_ready, s_valid          : std_logic;
  signal d_ready, d_valid          : std_logic;

  signal input                     : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal stream                    : SLVArray(0 to N - 1)(SW - 1 downto 0);
  signal output                    : SLVArray(0 to N - 1)(W - 1 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;

  end process CLK_PROCESS;

  START_GEN : process(clk) is

    constant LIMIT : integer := ((W + SW - 1) / SW) - 1;
    variable c     : integer range 0 to LIMIT;

  begin
    if rising_edge(clk) then
      if (rst = '1') then
        c     := LIMIT;
        start <= '0';
        start_delayed <= '0';
      else
        start_delayed <= start;
        if (c = 0) then
          start <= '1';
          c     := LIMIT;
        else
          start <= '0';
          c     := c - 1;
        end if;
      end if;
    end if;
  end process START_GEN;

  SERIALIZER_SR_3 : entity work.serializer_sr
    generic map (
      N  => N,
      W  => W,
      SW => SW
    )
    port map (
      CLK_I    => clk,
      RST_I    => rst,
      ENABLE_I => enable,
      START_I  => start,
      VALID_I  => s_valid,
      READY_O  => s_ready,
      DATA_I   => input,
      STREAM_O => stream
    );

  DESERIALIZER_SR_2 : entity work.deserializer_sr
    generic map (
      N  => N,
      W  => W,
      SW => SW
    )
    port map (
      CLK_I    => clk,
      RST_I    => rst,
      ENABLE_I => enable,
      START_I  => start,
      STREAM_I => stream,
      VALID_O  => d_valid,
      READY_I  => d_ready,
      DATA_O   => output,
      STALL_O  => open
    );

  TEST_STIM : process is
  begin

    wait for 1 ps;
    rst    <= '1';
    enable <= '0';
    wait for CLK_PERIOD / 2;
    enable <= '1';
    rst    <= '0';
    load_and_store (
      W     => W,
      SW => SW,
      value => (X"A2", X"DF", X"04", X"33"),
      input => input,
      ser_ready => s_ready,
      ser_valid => s_valid,
      dser_ready => d_ready,
      dser_valid => d_valid
      );
    wait;

  end process TEST_STIM;

  TEST_ASSER : process is
  begin

    wait for 1 ps;
    wait for 3 * CLK_PERIOD / 2;
    wait for CLK_PERIOD * (W);
    assert_equivalence (
      N      => N,
      input  => input,
      output => output);
    wait;

  end process TEST_ASSER;

end architecture TB;
