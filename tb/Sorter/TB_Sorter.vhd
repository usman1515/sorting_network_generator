----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_Sorter - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for a sorter.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity TB_SORTER is
end entity TB_SORTER;

architecture TB of TB_SORTER is

  constant CKTIME        : time := 10 ns;
  signal   clk           : std_logic;

  constant W             : integer := 8;
  constant SW            : integer := 1;
  constant N             : integer := 2;
  constant M             : integer := 2;
  signal   rst           : std_logic; -- Debounced reset signal.
  signal   enable        : std_logic; -- Debounced enable signal.
  --
  signal data_unsorted   : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal write_ready     : std_logic;
  signal write_valid     : std_logic;

  signal data_sorted     : SLVArray(0 to N - 1)(W - 1 downto 0);
  signal read_ready      : std_logic;
  signal read_valid      : std_logic;

  constant NUM_DATA      : integer := 2;

  type stim_t is array (0 to NUM_DATA - 1) of SLVArray(0 to  N - 1) (W - 1 downto 0);

  constant STIM_DATA     : stim_t :=
  (
    (
      X"7F",
      X"80"                           --,
      -- X"04",
      -- X"33"
    ),
    (
      X"80",
      X"7F"                           --,
      -- X"04",
      -- X"33"
    )
    -- (
    --   X"04",
    --   X"DF",
    --   X"A2",
    --   X"33"
    -- ),
    -- (
    --   X"33",
    --   X"DF",
    --   X"04",
    --   X"A2"
    -- )
  );

begin

  SORTER_1 : entity work.sorter
    generic map (
      W  => W,
      SW => SW,
      N  => N,
      M  => M
    )
    port map (
      CLK_I            => clk,
      ENABLE_I         => enable,
      RST_I            => rst,
      DATA_IN_READY_O  => write_ready,
      DATA_IN_VALID_I  => write_valid,
      DATA_I           => data_unsorted,
      DATA_OUT_READY_I => read_ready,
      DATA_OUT_VALID_O => read_valid,
      DATA_O           => data_sorted
    );

  CLK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLK_PROCESS;

  STIMULUS : process is
  begin

    enable        <= '0';
    rst           <= '1';
    wait for CKTIME /2 ;
    write_valid   <= '0';
    data_unsorted <= (others =>(others => '0'));
    wait for CKTIME;
    rst           <= '0';
    enable        <= '1';

    for i in 0 to NUM_DATA - 1 loop

      write_valid   <= '1';
      data_unsorted <= STIM_DATA(i);
      while (write_ready = '0') loop

        wait for CKTIME;

      end loop;
      write_valid <= '0';
      wait for CKTIME;



    end loop;

    wait;

  end process STIMULUS;

  TEST : process is

  begin

    wait for CKTIME /2 ;
    read_ready <= '0';
    wait for CKTIME;

    for i in 0 to NUM_DATA - 1 loop

      read_ready <= '0';

      while (read_valid = '0') loop

        wait for CKTIME;

      end loop;

      read_ready <= '1';
      wait for CKTIME;

      for j in 0 to N - 1 loop

        assert (data_sorted(i) = STIM_DATA(i)(j));

      end loop;

    end loop;

    wait;

  end process TEST;

end architecture TB;
