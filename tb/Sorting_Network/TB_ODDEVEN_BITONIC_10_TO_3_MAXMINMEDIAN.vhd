-------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_ODDEVEN_BITONIC_10_TO_3_MAXMINMEDIAN - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for synchronous ODDEVEN_10_TO_3_MAX/MIN/MEDIAN sorting
-- network with 10 inputs and 3 outputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_ODDEVEN_BITONIC_10_TO_3_MAXMINMEDIAN is
end entity TB_ODDEVEN_BITONIC_10_TO_3_MAXMINMEDIAN;

architecture TB of TB_ODDEVEN_BITONIC_10_TO_3_MAXMINMEDIAN is

  constant W                   : integer := 8;
  constant DEPTH               : integer := 6;
  constant N                   : integer := 10;
  constant M                   : integer := 3;

  constant CKTIME              : time := 10 ns;
  signal   clk                 : std_logic;

  signal rst_i                 : std_logic;
  signal e_i                   : std_logic;

  -- input signal for all networks
  signal a0_i                  : SLVArray(0 to N - 1)(W - 1 downto 0);
  -- Expected output for all networks
  signal max_i                 : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal min_i                 : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal median_i              : SLVArray(0 to M - 1)(W - 1 downto 0);
  -- Output of all networks
  -- OddEven
  signal oe_max_i              : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal oe_min_i              : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal oe_median_i           : SLVArray(0 to M - 1)(W - 1 downto 0);
  -- Bitonic
  signal b_max_i               : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal b_min_i               : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal b_median_i            : SLVArray(0 to M - 1)(W - 1 downto 0);

begin

  ODDEVEN_10TO3_MAX_1 : entity work.oddeven_10_to_3_max
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => oe_max_i
    );

  ODDEVEN_10TO3_MIN_1 : entity work.oddeven_10_to_3_min
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => oe_min_i
    );

  ODDEVEN_10TO3_MEDIAN_1 : entity work.oddeven_10_to_3_median
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => oe_median_i
    );

  BITONIC_10TO3_MAX_1 : entity work.bitonic_10_to_3_max
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => b_max_i
    );

  BITONIC_10TO3_MIN_1 : entity work.bitonic_10_to_3_min
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => b_min_i
    );

  BITONIC_10TO3_MEDIAN_1 : entity work.bitonic_10_to_3_median
    generic map (
      W => W
    )
    port map (
      CLK    => clk,
      E      => e_i,
      RST    => rst_i,
      INPUT  => a0_i,
      OUTPUT => b_median_i
    );

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  TEST_PROCESS : process is

  begin

    max_i <= (others => (others => '0'));
    e_i   <= '0';
    wait for CKTIME / 2;
    rst_i <= '1';
    wait for CKTIME;
    a0_i  <= (X"2B", X"A8", X"F2", X"5C", X"2B", X"F8", X"41", X"73", X"55", X"E1");
    rst_i <= '0';
    e_i   <= '1';
    wait for (W) * CKTIME;
    -- F8 F2 E1 A8 73 5C 55 41 2B 2B
    max_i    <= (X"F8", X"F2", X"E1");
    min_i    <= (X"41", X"55", X"73");
    median_i <= (X"A8", X"73", X"5C");
    a0_i     <= (X"12", X"48", X"B2", X"5C", X"2B", X"A8", X"C2", X"5C", X"71", X"05");

    wait for 2 * CKTIME;

    for i in 0 to M - 1 loop

      assert oe_max_i(i) = max_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(oe_max_i(i)))) &
               " max_i(i)= " & integer'image(to_integer(unsigned(max_i(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert oe_min_i(i) = min_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " oe_min_i(i)=   " & integer'image(to_integer(unsigned(oe_min_i(i)))) &
               " min_i(i)= " & integer'image(to_integer(unsigned(min_i(i)))) &
               " Expectation  oe_min_i(i) = min_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert oe_median_i(i) = median_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " oe_median_i(i)=   " & integer'image(to_integer(unsigned(oe_median_i(i)))) &
               " median_i(i)= " & integer'image(to_integer(unsigned(median_i(i)))) &
               " Expectation  oe_median_i(i) = median_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_max_i(i) = max_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(b_max_i(i)))) &
               " max_i(i)= " & integer'image(to_integer(unsigned(max_i(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_min_i(i) = min_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " b_min_i(i)=   " & integer'image(to_integer(unsigned(b_min_i(i)))) &
               " min_i(i)= " & integer'image(to_integer(unsigned(min_i(i)))) &
               " Expectation  b_min_i(i) = min_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_median_i(i) = median_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " b_median_i(i)=   " & integer'image(to_integer(unsigned(b_median_i(i)))) &
               " median_i(i)= " & integer'image(to_integer(unsigned(median_i(i)))) &
               " Expectation  oe_median_i(i) = median_i(i)";

    end loop;

    wait for CKTIME;
    -- C2 B2 A8 71 5C 5C 48 2B 12 05
    max_i    <= (X"C2", X"B2", X"A8");
    min_i    <= (X"05", X"12", X"2B");
    median_i <= (X"5C", X"5C", X"48");

    wait for W * CKTIME;

    for i in 0 to M - 1 loop

      assert oe_max_i(i) = max_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(oe_max_i(i)))) &
               " max_i(i)= " & integer'image(to_integer(unsigned(max_i(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert oe_min_i(i) = min_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " oe_min_i(i)=   " & integer'image(to_integer(unsigned(oe_min_i(i)))) &
               " min_i(i)= " & integer'image(to_integer(unsigned(min_i(i)))) &
               " Expectation  oe_min_i(i) = min_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert oe_median_i(i) = median_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " oe_median_i(i)=   " & integer'image(to_integer(unsigned(oe_median_i(i)))) &
               " median_i(i)= " & integer'image(to_integer(unsigned(median_i(i)))) &
               " Expectation  oe_median_i(i) = median_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_max_i(i) = max_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " B(i)=   " & integer'image(to_integer(unsigned(b_max_i(i)))) &
               " max_i(i)= " & integer'image(to_integer(unsigned(max_i(i)))) &
               " Expectation  B(i) = A_Sorted(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_min_i(i) = min_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " b_min_i(i)=   " & integer'image(to_integer(unsigned(b_min_i(i)))) &
               " min_i(i)= " & integer'image(to_integer(unsigned(min_i(i)))) &
               " Expectation  b_min_i(i) = min_i(i)";

    end loop;

    for i in 0 to M - 1 loop

      assert b_median_i(i) = median_i(i)
        report "Mismatch:: " &
               " i=      " & integer'image(i) &
               " b_median_i(i)=   " & integer'image(to_integer(unsigned(b_median_i(i)))) &
               " median_i(i)= " & integer'image(to_integer(unsigned(median_i(i)))) &
               " Expectation  oe_median_i(i) = median_i(i)";

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture TB;
