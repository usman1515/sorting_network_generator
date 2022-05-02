----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_CS - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Test Bench for all CS elements.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity TB_CS is
  --  Port ( );
end entity TB_CS;

architecture TB of TB_CS is

  constant CKTIME                          : time := 10 ns;

  procedure serialize (
    constant W_i      : in integer;
    constant SW_i     : in integer;
    constant value_a0 : in std_logic_vector;
    constant value_b0 : in std_logic_vector;
    signal start_i    : out std_logic;
    signal serial_a0  : out std_logic_vector;
    signal serial_b0  : out std_logic_vector
  ) is
  begin

    start_i <= '1';

    if (W_i mod SW_i > 0) then
      -- Add padding before MSB if W_i is not a multiple of SW_i.
      serial_a0(SW_i - 1 downto W_i mod SW_i ) <= (others => '0');
      serial_a0(W_i mod SW_i - 1 downto 0)     <= value_a0(W_i - 1 downto SW_i * (W_i / SW_i));
      serial_b0(SW_i - 1 downto W_i mod SW_i ) <= (others => '0');
      serial_b0(W_i mod SW_i - 1 downto 0)     <= value_b0(W_i - 1 downto SW_i * (W_i / SW_i));

      wait for CKTIME;
      start_i <= '0';
    end if;

    for i in (W_i / SW_i) - 1 downto 0 loop

      serial_a0 <= value_a0(SW_i * (i + 1) - 1 downto SW_i * i);
      serial_b0 <= value_b0(SW_i * (i + 1) - 1 downto SW_i * i);

      wait for CKTIME;
      start_i <= '0';

    end loop;

  end procedure serialize;

  procedure deserialize (
    constant W_i     : in integer;
    constant SW_i    : in integer;
    signal serial_a1 : in std_logic_vector;
    signal serial_b1 : in std_logic_vector;
    signal value_a1  : out std_logic_vector;
    signal value_b1  : out std_logic_vector
  ) is
  begin

    if (W_i mod SW_i > 0) then
      value_a1(W_i - 1 downto SW_i*(W_i/SW_i)) <= serial_a1(W_i mod SW_i - 1 downto 0);
      value_b1(W_i - 1 downto SW_i*(W_i/SW_i)) <= serial_b1(W_i mod SW_i - 1 downto 0);
      wait for CKTIME;
    end if;

    for i in (W_i / SW_i) - 1 downto 0 loop

      value_a1(SW_i*(i + 1) - 1 downto SW_i*i) <= serial_a1;
      value_b1(SW_i*(i + 1) - 1 downto SW_i*i) <= serial_b1;
      wait for CKTIME;

    end loop;

  end procedure deserialize;

  procedure assert_order (
    signal a0 : in std_logic_vector;
    signal b0 : in std_logic_vector;
    signal a1 : in std_logic_vector;
    signal b1 : in std_logic_vector
  ) is
  begin

    if (unsigned(a0) >= unsigned(b0)) then
      assert ((a0 = a1) and (b0 = b1))
        report "Mismatch:: " &
               " a0= " & integer'image(to_integer(unsigned(a0))) &
               " b0= " & integer'image(to_integer(unsigned(b0))) &
               " a1= " & integer'image(to_integer(unsigned(a1))) &
               " b1= " & integer'image(to_integer(unsigned(b1))) &
               " Expectation a0 = a1 and b0 = b1";
    else
      assert ((a0 = b1) and (b0 = a1))
        report "Mismatch:: " &
               " a0= " & integer'image(to_integer(unsigned(a0))) &
               " b0= " & integer'image(to_integer(unsigned(b0))) &
               " a1= " & integer'image(to_integer(unsigned(a1))) &
               " b1= " & integer'image(to_integer(unsigned(b1))) &
               " Expectation a0 = b1 and b0 = a1";
    end if;

  end procedure assert_order;

  signal clk                               : std_logic;

  constant W                               : integer := 8;
  constant SW                              : integer := 1;

  signal operand_a                         : std_logic_vector(7 downto 0);
  signal operand_b                         : std_logic_vector(7 downto 0);
  signal a0                                : std_logic_vector(0 downto 0);
  signal b0                                : std_logic_vector(0 downto 0);
  signal start                             : std_logic;

  signal a1_primitive                      : std_logic_vector(0 downto 0);
  signal b1_primitive                      : std_logic_vector(0 downto 0);
  signal result_a_primitive                : std_logic_vector(7 downto 0);
  signal result_b_primitive                : std_logic_vector(7 downto 0);

  signal a1_async                          : std_logic_vector(0 downto 0);
  signal b1_async                          : std_logic_vector(0 downto 0);
  signal result_a_async                    : std_logic_vector(7 downto 0);
  signal result_b_async                    : std_logic_vector(7 downto 0);

  signal a1_halfsync                       : std_logic_vector(0 downto 0);
  signal b1_halfsync                       : std_logic_vector(0 downto 0);
  signal result_a_halfsync                 : std_logic_vector(7 downto 0);
  signal result_b_halfsync                 : std_logic_vector(7 downto 0);

  signal a1_sync                           : std_logic_vector(0 downto 0);
  signal b1_sync                           : std_logic_vector(0 downto 0);
  signal result_a_sync                     : std_logic_vector(7 downto 0);
  signal result_b_sync                     : std_logic_vector(7 downto 0);

  signal a1_sw                             : std_logic_vector(0 downto 0);
  signal b1_sw                             : std_logic_vector(0 downto 0);
  signal result_a_sw                       : std_logic_vector(7 downto 0);
  signal result_b_sw                       : std_logic_vector(7 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  BITCS_0 : entity work.bitcs_primitive
    port map (
      A0    => a0(0),
      B0    => b0(0),
      A1    => a1_primitive(0),
      B1    => b1_primitive(0),
      START => start
    );

  BITCS_1 : entity work.bitcs
    port map (
      A0    => a0(0),
      B0    => b0(0),
      A1    => a1_async(0),
      B1    => b1_async(0),
      START => start
    );

  BITCS_2 : entity work.bitcs_halfsync
    port map (
      CLK   => clk,
      A0    => a0(0),
      B0    => b0(0),
      A1    => a1_halfsync(0),
      B1    => b1_halfsync(0),
      START => start
    );

  BITCS_3 : entity work.bitcs_sync
    port map (
      CLK   => clk,
      A0    => a0(0),
      B0    => b0(0),
      A1    => a1_sync(0),
      B1    => b1_sync(0),
      START => start
    );

  BITCS_4 : entity work.subwordcs
    generic map (
      SW => SW
    )
    port map (
      CLK   => clk,
      A0    => a0,
      B0    => b0,
      A1    => a1_SW,
      B1    => b1_SW,
      START => start
    );

  TEST_STIM : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    operand_a <= "10100111";
    operand_b <= "10110110";
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => SW,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start,
              serial_a0 => a0,
              serial_b0 => b0
              );

    operand_a <= "10110110";
    operand_b <= "10100111";
    serialize(W_i       => W,
              SW_i      => SW,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start,
              serial_a0 => a0,
              serial_b0 => b0
              );
    wait;

  end process TEST_STIM;

  TEST_ASSERT_PRIMITIVE : process is
  begin

    result_a_primitive <= (others => '0');
    result_b_primitive <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME;
    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_primitive,
    serial_b1 => b1_primitive,
    value_a1  => result_a_primitive,
    value_b1  => result_b_primitive
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_primitive,
      b1 => result_b_primitive);

    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_primitive,
    serial_b1 => b1_primitive,
    value_a1  => result_a_primitive,
    value_b1  => result_b_primitive
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_primitive,
      b1 => result_b_primitive);

    wait;

  end process TEST_ASSERT_PRIMITIVE;

  TEST_ASSERT_ASYNC : process is
  begin

    result_a_async <= (others => '0');
    result_b_async <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME;
    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_async,
    serial_b1 => b1_async,
    value_a1  => result_a_async,
    value_b1  => result_b_async
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_async,
      b1 => result_b_async);

    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_async,
    serial_b1 => b1_async,
    value_a1  => result_a_async,
    value_b1  => result_b_async
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_async,
      b1 => result_b_async);

    wait;

  end process TEST_ASSERT_ASYNC;

  TEST_ASSERT_HALFSYNC : process is
  begin

    result_a_halfsync <= (others => '0');
    result_b_halfsync <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_halfsync,
    serial_b1 => b1_halfsync,
    value_a1  => result_a_halfsync,
    value_b1  => result_b_halfsync
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_halfsync,
      b1 => result_b_halfsync);

    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_halfsync,
    serial_b1 => b1_halfsync,
    value_a1  => result_a_halfsync,
    value_b1  => result_b_halfsync
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_halfsync,
      b1 => result_b_halfsync);

    wait;

  end process TEST_ASSERT_HALFSYNC;

  TEST_ASSERT_SYNC : process is
  begin

    result_a_sync <= (others => '0');
    result_b_sync <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_sync,
    serial_b1 => b1_sync,
    value_a1  => result_a_sync,
    value_b1  => result_b_sync
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sync,
      b1 => result_b_sync);

    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_sync,
    serial_b1 => b1_sync,
    value_a1  => result_a_sync,
    value_b1  => result_b_sync
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sync,
      b1 => result_b_sync);

    wait;

  end process TEST_ASSERT_SYNC;

  TEST_ASSERT_SUBWORD : process is
  begin

    result_a_SW <= (others => '0');
    result_b_SW <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_SW,
    serial_b1 => b1_SW,
    value_a1  => result_a_SW,
    value_b1  => result_b_SW
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_SW,
      b1 => result_b_SW);

    deserialize(
    W_i       => W,
    SW_i      => SW,
    serial_a1 => a1_SW,
    serial_b1 => b1_SW,
    value_a1  => result_a_SW,
    value_b1  => result_b_SW
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_SW,
      b1 => result_b_SW);

    wait;

  end process TEST_ASSERT_SUBWORD;

end architecture TB;
