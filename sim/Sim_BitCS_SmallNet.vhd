----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SIM_BITCS_SMALLNET - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for asynchronous Bitserial Compare Swap component
-- with I/O shift registers and Cycle_Timer for control signal generation as a
-- small sorting network for 4 inputs.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity SIM_BITCS_SMALLNET is
  generic (
    W : integer := 8
  );
end entity SIM_BITCS_SMALLNET;

architecture BEHAVIORAL of SIM_BITCS_SMALLNET is

  constant CKTIME           : time := 10 ns;

  signal clk                : std_logic;

  type grid2d is array (3 downto 0) of std_logic_vector(3 downto 0);

  signal wire               : grid2d;

  signal start_i            : std_logic;
  signal e_i                : std_logic;
  signal rst_i              : std_logic;

  type memblock is array (3 downto 0) of std_logic_vector(W - 1 downto 0);

  signal a_vec              : memblock;
  signal b_vec              : memblock;

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  TEST_PROCESS : process is

  begin

    a_vec <= (X"5C", X"2B", X"A8", X"F2");
    b_vec <= (others => (others => '0'));
    e_i   <= '0';
    wait for CKTIME / 2;
    rst_i <= '1';
    wait for CKTIME;
    rst_i <= '0';
    e_i   <= '1';
    wait for (W - 1) * CKTIME;
    -- assert ((larger_value = A1) and (smaller_value = D)) report "Mismatch:: " &
    --   " A0= " & integer'image(to_integer(unsigned(larger_value))) &
    --   " B0= " & integer'image(to_integer(unsigned(smaller_value))) &
    --   " C= " & integer'image(to_integer(unsigned(C))) &
    --   " D= " & integer'image(to_integer(unsigned(D))) &
    --   " Expectation A=C and B=D";

    -- A <= X"a6";
    -- B <= X"b7";

    -- wait for (w-1)*ckTime;
    -- assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
    --   " A= " & integer'image(to_integer(unsigned(smaller_value))) &
    --   " B= " & integer'image(to_integer(unsigned(larger_value))) &
    --   " C= " & integer'image(to_integer(unsigned(C))) &
    --   " D= " & integer'image(to_integer(unsigned(D))) &
    --   " Expectation A=D and B=C";
    wait;

  end process TEST_PROCESS;

  INPUTSHIFT : for i in 0 to 3 generate

    LSR : entity work.load_shift_register
      generic map (
        W => W
      )
      port map (
        CLK        => clk,
        E          => e_i,
        LOAD       => start_i,
        PAR_INPUT  => a_vec(i),
        SER_OUTPUT => wire(0)(i)
      );

  end generate INPUTSHIFT;

  OUTPUTSHIFT : for i in 0 to 3 generate

    SSR : entity work.store_shift_register
      generic map (
        W => W
      )
      port map (
        CLK        => clk,
        E          => e_i,
        STORE      => start_i,
        PAR_OUTPUT => b_vec(i),
        SER_INPUT  => wire(3)(i)
      );

  end generate OUTPUTSHIFT;

  BITCS_0 : entity work.bitcs
    port map (
      A0    => wire(0)(1),
      B0    => wire(0)(0),
      A1    => wire(1)(1),
      B1    => wire(1)(0),
      START => start_i
    );

  BITCS_1 : entity work.bitcs
    port map (
      A0    => wire(0)(3),
      B0    => wire(0)(2),
      A1    => wire(1)(3),
      B1    => wire(1)(2),
      START => start_i
    );

  BITCS_2 : entity work.bitcs
    port map (
      A0    => wire(1)(3),
      B0    => wire(1)(1),
      A1    => wire(2)(3),
      B1    => wire(2)(1),
      START => start_i
    );

  BITCS_3 : entity work.bitcs
    port map (
      A0    => wire(1)(2),
      B0    => wire(1)(0),
      A1    => wire(2)(2),
      B1    => wire(2)(0),
      START => start_i
    );

  BITCS_4 : entity work.bitcs
    port map (
      A0    => wire(2)(2),
      B0    => wire(2)(1),
      A1    => wire(3)(2),
      B1    => wire(3)(1),
      START => start_i
    );

  wire(3)(3) <= wire(2)(3);
  wire(3)(0) <= wire(2)(0);

  CYCLE_TIMER_1 : entity work.cycle_timer
    generic map (
      W => W
    )
    port map (
      CLK   => clk,
      RST   => rst_i,
      E     => e_i,
      START => start_i
    );

end architecture BEHAVIORAL;
