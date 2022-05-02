----------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_SUBWORDCS - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Test Bench for SUBWORDCS with different subword lengths.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity TB_SUBWORDCS is
  --  Port ( );
end entity TB_SUBWORDCS;

architecture TB of TB_SUBWORDCS is

  constant CKTIME                              : time := 10 ns;

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

  signal clk                                   : std_logic;

  constant W                                   : integer := 8;

  signal operand_a                             : std_logic_vector(7 downto 0);
  signal operand_b                             : std_logic_vector(7 downto 0);

  signal start_sw1                             : std_logic;
  signal a0_sw1                                : std_logic_vector(0 downto 0);
  signal b0_sw1                                : std_logic_vector(0 downto 0);
  signal a1_sw1                                : std_logic_vector(0 downto 0);
  signal b1_sw1                                : std_logic_vector(0 downto 0);
  signal result_a_sw1                          : std_logic_vector(7 downto 0);
  signal result_b_sw1                          : std_logic_vector(7 downto 0);

  signal start_sw2                             : std_logic;
  signal a0_sw2                                : std_logic_vector(1 downto 0);
  signal b0_sw2                                : std_logic_vector(1 downto 0);
  signal a1_sw2                                : std_logic_vector(1 downto 0);
  signal b1_sw2                                : std_logic_vector(1 downto 0);
  signal result_a_sw2                          : std_logic_vector(7 downto 0);
  signal result_b_sw2                          : std_logic_vector(7 downto 0);

  signal start_sw3                             : std_logic;
  signal a0_sw3                                : std_logic_vector(2 downto 0);
  signal b0_sw3                                : std_logic_vector(2 downto 0);
  signal a1_sw3                                : std_logic_vector(2 downto 0);
  signal b1_sw3                                : std_logic_vector(2 downto 0);
  signal result_a_sw3                          : std_logic_vector(7 downto 0);
  signal result_b_sw3                          : std_logic_vector(7 downto 0);

  signal start_sw4                             : std_logic;
  signal a0_sw4                                : std_logic_vector(3 downto 0);
  signal b0_sw4                                : std_logic_vector(3 downto 0);
  signal a1_sw4                                : std_logic_vector(3 downto 0);
  signal b1_sw4                                : std_logic_vector(3 downto 0);
  signal result_a_sw4                          : std_logic_vector(7 downto 0);
  signal result_b_sw4                          : std_logic_vector(7 downto 0);

  signal start_sw5                             : std_logic;
  signal a0_sw5                                : std_logic_vector(4 downto 0);
  signal b0_sw5                                : std_logic_vector(4 downto 0);
  signal a1_sw5                                : std_logic_vector(4 downto 0);
  signal b1_sw5                                : std_logic_vector(4 downto 0);
  signal result_a_sw5                          : std_logic_vector(7 downto 0);
  signal result_b_sw5                          : std_logic_vector(7 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  SUBWORDCS_1 : entity work.subwordcs
    generic map (
      SW => 1
    )
    port map (
      CLK   => clk,
      A0    => a0_sw1,
      B0    => b0_sw1,
      A1    => a1_sw1,
      B1    => b1_sw1,
      START => start_sw1
    );

  SUBWORDCS_2 : entity work.subwordcs
    generic map (
      SW => 2
    )
    port map (
      CLK   => clk,
      A0    => a0_sw2,
      B0    => b0_sw2,
      A1    => a1_sw2,
      B1    => b1_sw2,
      START => start_sw2
    );

  SUBWORDCS_3 : entity work.subwordcs
    generic map (
      SW => 3
    )
    port map (
      CLK   => clk,
      A0    => a0_sw3,
      B0    => b0_sw3,
      A1    => a1_sw3,
      B1    => b1_sw3,
      START => start_sw3
    );

  SUBWORDCS_4 : entity work.subwordcs
    generic map (
      SW => 4
    )
    port map (
      CLK   => clk,
      A0    => a0_sw4,
      B0    => b0_sw4,
      A1    => a1_sw4,
      B1    => b1_sw4,
      START => start_sw4
    );

  SUBWORDCS_5 : entity work.subwordcs
    generic map (
      SW => 5
    )
    port map (
      CLK   => clk,
      A0    => a0_sw5,
      B0    => b0_sw5,
      A1    => a1_sw5,
      B1    => b1_sw5,
      START => start_sw5
    );

  TEST_STIM_SW1 : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    operand_a <= "10100111";
    operand_b <= "10110110";
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => 1,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw1,
              serial_a0 => a0_sw1,
              serial_b0 => b0_sw1
              );

    operand_a <= "10110110";
    operand_b <= "10100111";
    serialize(W_i       => W,
              SW_i      => 1,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw1,
              serial_a0 => a0_sw1,
              serial_b0 => b0_sw1
              );
    wait;

  end process TEST_STIM_SW1;

  TEST_ASSERT_SW1 : process is
  begin

    result_a_sw1 <= (others => '0');
    result_b_sw1 <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => 1,
    serial_a1 => a1_sw1,
    serial_b1 => b1_sw1,
    value_a1  => result_a_sw1,
    value_b1  => result_b_sw1
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw1,
      b1 => result_b_sw1);

    deserialize(
    W_i       => W,
    SW_i      => 1,
    serial_a1 => a1_sw1,
    serial_b1 => b1_sw1,
    value_a1  => result_a_sw1,
    value_b1  => result_b_sw1
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw1,
      b1 => result_b_sw1);

    wait;

  end process TEST_ASSERT_SW1;

  TEST_STIM_SW2 : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => 2,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw2,
              serial_a0 => a0_sw2,
              serial_b0 => b0_sw2
              );

    serialize(W_i       => W,
              SW_i      => 2,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw2,
              serial_a0 => a0_sw2,
              serial_b0 => b0_sw2
              );
    wait;

  end process TEST_STIM_SW2;

  TEST_ASSERT_SW2 : process is
  begin

    result_a_sw2 <= (others => '0');
    result_b_sw2 <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => 2,
    serial_a1 => a1_sw2,
    serial_b1 => b1_sw2,
    value_a1  => result_a_sw2,
    value_b1  => result_b_sw2
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw2,
      b1 => result_b_sw2);

    deserialize(
    W_i       => W,
    SW_i      => 2,
    serial_a1 => a1_sw2,
    serial_b1 => b1_sw2,
    value_a1  => result_a_sw2,
    value_b1  => result_b_sw2
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw2,
      b1 => result_b_sw2);

    wait;

  end process TEST_ASSERT_SW2;

  TEST_STIM_SW3 : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => 3,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw3,
              serial_a0 => a0_sw3,
              serial_b0 => b0_sw3
              );

    serialize(W_i       => W,
              SW_i      => 3,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw3,
              serial_a0 => a0_sw3,
              serial_b0 => b0_sw3
              );
    wait;

  end process TEST_STIM_SW3;

  TEST_ASSERT_SW3 : process is
  begin

    result_a_sw3 <= (others => '0');
    result_b_sw3 <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => 3,
    serial_a1 => a1_sw3,
    serial_b1 => b1_sw3,
    value_a1  => result_a_sw3,
    value_b1  => result_b_sw3
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw3,
      b1 => result_b_sw3);

    deserialize(
    W_i       => W,
    SW_i      => 3,
    serial_a1 => a1_sw3,
    serial_b1 => b1_sw3,
    value_a1  => result_a_sw3,
    value_b1  => result_b_sw3
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw3,
      b1 => result_b_sw3);

    wait;

  end process TEST_ASSERT_SW3;

  TEST_STIM_SW4 : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => 4,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw4,
              serial_a0 => a0_sw4,
              serial_b0 => b0_sw4
              );

    serialize(W_i       => W,
              SW_i      => 4,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw4,
              serial_a0 => a0_sw4,
              serial_b0 => b0_sw4
              );
    wait;

  end process TEST_STIM_SW4;

  TEST_ASSERT_SW4 : process is
  begin

    result_a_sw4 <= (others => '0');
    result_b_sw4 <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => 4,
    serial_a1 => a1_sw4,
    serial_b1 => b1_sw4,
    value_a1  => result_a_sw4,
    value_b1  => result_b_sw4
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw4,
      b1 => result_b_sw4);

    deserialize(
    W_i       => W,
    SW_i      => 4,
    serial_a1 => a1_sw4,
    serial_b1 => b1_sw4,
    value_a1  => result_a_sw4,
    value_b1  => result_b_sw4
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw4,
      b1 => result_b_sw4);

    wait;

  end process TEST_ASSERT_SW4;

  TEST_STIM_SW5 : process is

  begin

    -- Functional check:
    -- A is first equal then larger, then equal and then smaller than B.
    wait for CKTIME / 2;

    serialize(W_i       => W,
              SW_i      => 5,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw5,
              serial_a0 => a0_sw5,
              serial_b0 => b0_sw5
              );

    serialize(W_i       => W,
              SW_i      => 5,
              value_a0  => operand_a,
              value_b0  => operand_b,
              start_i   => start_sw5,
              serial_a0 => a0_sw5,
              serial_b0 => b0_sw5
              );
    wait;

  end process TEST_STIM_SW5;

  TEST_ASSERT_SW5 : process is
  begin

    result_a_sw5 <= (others => '0');
    result_b_sw5 <= (others => '0');
    wait for CKTIME / 2;
    wait for CKTIME * 2;
    deserialize(
    W_i       => W,
    SW_i      => 5,
    serial_a1 => a1_sw5,
    serial_b1 => b1_sw5,
    value_a1  => result_a_sw5,
    value_b1  => result_b_sw5
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw5,
      b1 => result_b_sw5);

    deserialize(
    W_i       => W,
    SW_i      => 5,
    serial_a1 => a1_sw5,
    serial_b1 => b1_sw5,
    value_a1  => result_a_sw5,
    value_b1  => result_b_sw5
    );

    assert_order (
      a0 => operand_a,
      b0 => operand_b,
      a1 => result_a_sw5,
      b1 => result_b_sw5);

    wait;

  end process TEST_ASSERT_SW5;
end architecture TB;
