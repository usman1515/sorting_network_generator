----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: TB_IO_Shift_Registers_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Simulation for I/O shift registers.
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.MATH_REAL.all;

library work;
  use work.CustomTypes.all;

entity TB_IO_SHIFT_REGISTERS_BRAM is
  --  Port ( );
end entity TB_IO_SHIFT_REGISTERS_BRAM;

architecture TB of TB_IO_SHIFT_REGISTERS_BRAM is

  constant CKTIME              : time := 10 ns;
  constant W                   : integer := 8;
  constant SW                  : integer := 1;
  signal   clk                 : std_logic;
  signal   rst                 : std_logic;
  signal   e_i                 : std_logic;
  signal   load_i              : std_logic_vector(0 downto 0);
  signal   store_i             : std_logic_vector(0 downto 0);
  signal   input_i             : std_logic_vector(W - 1 downto 0);
  signal   serial_i            : std_logic_vector(SW -1 downto 0);
  signal   output_i            : std_logic_vector(W - 1 downto 0);

  constant ADDR_WIDTH          : integer := integer(ceil(log2(real(W))));
  signal   raddr               : integer range 0 to W - 1;
  signal   slv_raddr           : std_logic_vector(ADDR_WIDTH - 1 downto 0);

  signal waddr                 : integer range 0 to W - 1;
  signal slv_waddr             : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin

  CLOCK_PROCESS : process is
  begin

    clk <= '0';
    wait for CKTIME / 2;
    clk <= '1';
    wait for CKTIME / 2;

  end process CLOCK_PROCESS;

  SET_SLV_RADDR : process (raddr) is
  begin

    slv_raddr <= std_logic_vector(to_unsigned(raddr, ADDR_WIDTH));

  end process SET_SLV_RADDR;

  SET_SLV_WADDR : process (raddr) is
  begin

    slv_waddr <= std_logic_vector(to_unsigned(waddr, ADDR_WIDTH));

  end process SET_SLV_WADDR;

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER_READ : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '1' or load_i = "1") then
        raddr <= (W + SW - 1)/SW - 3;
      else
        if (e_i = '1') then
          if (raddr = 0) then
            raddr <= (W + SW - 1)/SW - 1;
          else
            raddr <= raddr - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER_READ;

  COUNTER_WRITE : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (rst = '1' or load_i = "1") then
        waddr <= (W + SW - 1)/ SW - 1;
      else
        if (e_i = '1') then
          if (waddr = 0) then
            waddr <= (W + SW - 1)/ SW - 1;
          else
            waddr <= waddr - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER_WRITE;

  LOAD_SHIFT_REGISTER_BRAM_1 : entity work.load_shift_register_bram
    generic map (
      W => W,
      SW => SW
    )
    port map (
      CLK        => clk,
      RST        => rst,
      E          => e_i,
      LOAD       => load_i(0),
      RADDR      => slv_raddr,
      PAR_INPUT  => input_i,
      SER_OUTPUT => serial_i
    );

  STORE_SHIFT_REGISTER_1 : entity work.store_shift_register_bram
    generic map (
      W => W,
      SW => SW
    )
    port map (
      CLK        => clk,
      RST        => rst,
      STORE      => store_i(0),
      WADDR      => slv_waddr,
      E          => e_i,
      SER_INPUT  => serial_i,
      PAR_OUTPUT => output_i
    );

  TEST_PROCESS : process is
  begin

    wait for 1 * ps;
    wait for CKTIME / 2;
    rst     <= '1';
    e_i     <= '0';
    wait for CKTIME * 2;
    input_i <= (others => '0');
    load_i  <= "0";
    store_i <= "0";
    wait for CKTIME;
    rst     <= '0';
    e_i     <= '1';
    input_i <= "11001011";
    load_i  <= "1";

    for i in 0 to (W + SW - 1)/SW - 3 loop

      wait for CKTIME;
      load_i <= "0";

    end loop;

    e_i     <= '0';
    wait for CKTIME * 2;
    e_i     <= '1';
    wait for CKTIME * 2;
    store_i <= "1";
    load_i  <= "1";
    input_i <= "00101010";
    wait for CKTIME;
    store_i <= "0";
    load_i  <= "0";
    -- assert (input_i = output_i)
    --   report "Mismatch:: " &
    --          " input_i= " & integer'image(to_integer(unsigned(input_i))) &
    --          " output_i= " & integer'image(to_integer(unsigned(output_i))) &
    --          " Expectation= input_i=output_i";

    wait for ((W + SW - 1)/SW - 1) * CKTIME;
    store_i <= "1";
    wait for CKTIME;
    store_i <= "0";
    wait;

  end process TEST_PROCESS;

end architecture TB;
