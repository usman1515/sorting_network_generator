----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_BITCS_ShiftReg - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for asynchronous Bitserial Compare Swap component
-- with I/O shift registers.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity TB_BITCS_SHIFTREG is
  generic (
    W : integer := 8
  );
end entity TB_BITCS_SHIFTREG;

architecture TB of TB_BITCS_SHIFTREG is

  component BITCS is
    port (
      A0    : in    std_logic;
      B0    : in    std_logic;
      A1    : out   std_logic;
      B1    : out   std_logic;
      START : in    std_logic
    );
  end component bitcs;

  component LOAD_SHIFT_REGISTER is
    generic (
      W : integer
    );
    port (
      CLK            : in    std_logic;
      E              : in    std_logic;
      LOAD           : in    std_logic;
      PAR_INPUT      : in    std_logic_vector(W - 1 downto 0);
      SER_OUTPUT     : out   std_logic
    );
  end component load_shift_register;

  component STORE_SHIFT_REGISTER is
    generic (
      W : integer
    );
    port (
      CLK           : in    std_logic;
      E             : in    std_logic;
      STORE         : in    std_logic;
      SER_INPUT     : in    std_logic;
      PAR_OUTPUT    : out   std_logic_vector(W - 1 downto 0)
    );
  end component store_shift_register;

  constant CKTIME                        : time := 10 ns;

  signal clk                             : std_logic;
  signal a0_i                            : std_logic;
  signal b0_i                            : std_logic;
  signal a1_i                            : std_logic;
  signal b1_i                            : std_logic;
  signal start_i                         : std_logic;

  signal e_i                             : std_logic;
  signal load_i                          : std_logic;
  signal store_i                         : std_logic;

  signal a_vec_i                         : std_logic_vector(W - 1 downto 0);
  signal b_vec_i                         : std_logic_vector(W - 1 downto 0);
  signal a_vec_res_i                     : std_logic_vector(W - 1 downto 0);
  signal b_vec_res_i                     : std_logic_vector(W - 1 downto 0);

  signal larger_value_i                  : std_logic_vector(W - 1 downto 0);
  signal smaller_value_i                 : std_logic_vector(W - 1 downto 0);

begin

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  UUT_0 : entity work.bitcs
    port map (
      A0    => a0_i,
      B0    => b0_i,
      A1    => a1_i,
      B1    => b1_i,
      START => start_i
    );

  LOAD_SHIFT_REGISTER_1 : entity work.load_shift_register
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E        => e_i,
      LOAD       => load_i,
      PAR_INPUT  => a_vec_i,
      SER_OUTPUT => a0_i
    );

  LOAD_SHIFT_REGISTER_2 : entity work.load_shift_register
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E        => e_i,
      LOAD       => load_i,
      PAR_INPUT  => b_vec_i,
      SER_OUTPUT => b0_i
    );

  STORE_SHIFT_REGISTER_1 : entity work.store_shift_register
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E        => e_i,
      STORE      => store_i,
      SER_INPUT  => a1_i,
      PAR_OUTPUT => a_vec_res_i
    );

  STORE_SHIFT_REGISTER_2 : entity work.store_shift_register
    generic map (
      W => W
    )
    port map (
      CLK        => clk,
      E        => e_i,
      STORE      => store_i,
      SER_INPUT  => b1_i,
      PAR_OUTPUT => b_vec_res_i
    );

  TEST_PROCESS : process is

  begin

    larger_value_i  <= "10110110";
    smaller_value_i <= "10100111";
    wait for CKTIME / 2 + 1 ps;

    e_i <= '1';

    a_vec_i <= larger_value_i;
    b_vec_i <= smaller_value_i;

    for i in 0 to W - 1 loop

      wait for CKTIME;

      if (i = 0) then
        load_i  <= '1';
        start_i <= '1';
        store_i <= '1';
      else
        load_i  <= '0';
        start_i <= '0';
        store_i <= '0';
      end if;

    end loop;

    a_vec_i <= smaller_value_i;
    b_vec_i <= larger_value_i;

    for i in 0 to W - 1 loop

      wait for CKTIME;

      if (i = 0) then
        load_i  <= '1';
        start_i <= '1';
        store_i <= '1';
      else
        load_i  <= '0';
        start_i <= '0';
        store_i <= '0';
      end if;

      if (i = 1) then
        assert ((larger_value_i = a_vec_res_i) and (smaller_value_i = b_vec_res_i))
          report "Mismatch:: " &
                 " A_vec_i= " & integer'image(to_integer(unsigned(larger_value_i))) &
                 " B_vec_i= " & integer'image(to_integer(unsigned(smaller_value_i))) &
                 " A_vec_res_i= " & integer'image(to_integer(unsigned(a_vec_res_i))) &
                 " b_vec_res_i= " & integer'image(to_integer(unsigned(b_vec_res_i))) &
                 " Expectation A_vec_i=A_vec_res_i and B_vec_i=b_vec_res_i";
      end if;

    end loop;

    for i in 0 to W - 1 loop

      wait for CKTIME;

      if (i = 0) then
        load_i  <= '1';
        start_i <= '1';
        store_i <= '1';
      else
        load_i  <= '0';
        start_i <= '0';
        store_i <= '0';
      end if;

      if (i = 1) then
        assert ((larger_value_i = a_vec_res_i) and (smaller_value_i = b_vec_res_i))
          report "Mismatch:: " &
                 " A_vec_i= " & integer'image(to_integer(unsigned(smaller_value_i))) &
                 " B_vec_i= " & integer'image(to_integer(unsigned(larger_value_i))) &
                 " A_vec_res_i= " & integer'image(to_integer(unsigned(a_vec_res_i))) &
                 " b_vec_res_i= " & integer'image(to_integer(unsigned(b_vec_res_i))) &
                 " Expectation A_vec_i=b_vec_res_i and B_vec_i=A_vec_res_i";
      end if;

    end loop;

    wait;

  end process TEST_PROCESS;

end architecture TB;
