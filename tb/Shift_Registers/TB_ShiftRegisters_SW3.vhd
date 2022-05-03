---------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_ShiftRegisters_SW3 - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for I/O shift registers with subwords.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity TB_SHIFTREGISTERS_SW3 is
  --  Port ( );
end entity TB_SHIFTREGISTERS_SW3;

architecture TB of TB_SHIFTREGISTERS_SW3 is

  constant CKTIME        : time := 10 ns;
  constant W             : integer := 8;
  constant SW            : integer := 3;

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal e_i             : std_logic;
  signal load_i          : std_logic_vector(0 downto 0);
  signal store_i         : std_logic_vector(0 downto 0);
  signal input_i         : std_logic_vector(W - 1 downto 0);
  signal serial_i        : std_logic_vector(SW - 1 downto 0);
  signal output_i        : std_logic_vector(W - 1 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  LOAD_SHIFT_REGISTER_SW_1 : entity work.load_shift_register_sw
    generic map (
      W  => W,
      SW => SW
    )
    port map (
      CLK        => clk,
      RST        => rst,
      LOAD       => load_i(0),
      E          => e_i,
      PAR_INPUT  => input_i,
      SER_OUTPUT => serial_i
    );

  STORE_SHIFT_REGISTER_SW_1 : entity work.store_shift_register_sw
    generic map (
      W  => W,
      SW => SW
    )
    port map (
      CLK        => clk,
      RST        => rst,
      STORE      => store_i(0),
      E          => e_i,
      SER_INPUT  => serial_i,
      PAR_OUTPUT => output_i
    );

  TEST_PROCESS : process is
  begin

    rst     <= '1';
    load_i  <= "0";
    store_i <= "0";
    wait for CKTIME;
    rst     <= '0';
    input_i <= "11001011";
    load_i  <= "1";
    e_i     <= '1';

    for i in 0 to ((W+ SW -1) / SW) - 1 loop

      wait for CKTIME;
      load_i <= "0";

    end loop;

    store_i <= "1";
    wait for CKTIME;
    store_i <= "0";
    assert (input_i = output_i)
      report "Mismatch:: " &
             " input_i= " & integer'image(to_integer(unsigned(input_i))) &
             " output_i= " & integer'image(to_integer(unsigned(output_i))) &
             " Expectation= input_i=output_i";

    wait;

  end process TEST_PROCESS;

end architecture TB;
