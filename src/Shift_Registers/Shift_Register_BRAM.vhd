----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SHIFT_REGISTER_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Shift register implemented with BRAM of w-width with serial in-/output.
-- Used as delay element.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library UNISIM;
  use UNISIM.vcomponents.all;

library UNIMACRO;
  use unimacro.Vcomponents.all;

entity SHIFT_REGISTER_BRAM is
  generic (
    -- Length of the shift_registers.
    W : integer := 8;
    -- Number of shift_registers
    N : integer := 1
  );
  port (
    -- System Clock
    CLK        : in    std_logic;
    -- Reset
    RST        : in    std_logic;
    -- Enable
    E          : in    std_logic;
    -- bit serial input
    SER_INPUT  : in    std_logic_vector(N - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT : out   std_logic_vector(N - 1 downto 0)
  );
end entity SHIFT_REGISTER_BRAM;

architecture BEHAVIORAL of SHIFT_REGISTER_BRAM is

  -- Calculate correct value for BRAM size dependent on W and N.
  -- For details see ug953 p.198.

  function get_bram_size (W_i : integer; N_i : integer) return string is
  begin

    if (N_i >= 37) then
      return "36Kb";
    else
      if (W_i * N_i > 18 * 1024) then
        return "36Kb";
      else
        return "16Kb";
      end if;
    end if;

  end function get_bram_size;

  -- Calculate correct address width based on W and N.
  -- Details are also to be found in ug953 p.198.

  function get_addr_width (W_i: integer; N_i : integer) return integer is
  begin

    if (N >= 37) then
      return 9;
    else
      if (W_i * N_i > 18 * 1024) then
        if (19 <= N_i and N_i <= 36) then
          return 10;
        end if;
        if (10 <= N_i and N_i <= 18) then
          return 11;
        end if;
        if (5 <= N_i and N_i <= 9) then
          return 12;
        end if;
        if (3 <= N_i and N_i <= 4) then
          return 13;
        end if;
        if (2 = N_i) then
          return 14;
        else
          return 15;
        end if;
      else
        if (19 <= N_i and N_i <= 36) then
          return 9;
        end if;
        if (10 <= N_i and N_i <= 18) then
          return 10;
        end if;
        if (5 <= N_i and N_i <= 9) then
          return 11;
        end if;
        if (3 <= N_i and N_i <= 4) then
          return 12;
        end if;
        if (2 = N_i) then
          return 13;
        else
          return 14;
        end if;
      end if;
    end if;

  end function get_addr_width;

  function get_we_width (N_i : integer) return integer is
  begin

    if (37 <= N_i and N_i <= 72) then
      return 8;
    end if;

    if (19 <= N_i and N_i <= 36) then
      return 4;
    end if;

    if (10 <= N_i and N_i <= 18) then
      return 2;
    else
      return 1;
    end if;

  end function get_we_width;

  function add_modulo(a : integer; b : integer; max : integer) return integer is
    begin
      return (a + b) mod (max + 1);
  end function add_modulo;

  constant BRAM_SIZE  : string := get_bram_size(W, N);
  constant ADDR_WIDTH : integer := get_addr_width(W, N);
  constant WE_WIDTH : integer := 4; --get_we_width(N);
  -- WARNING: No checks prevent a address depth exceeding the allowed bounds of
  -- the BRAM block !
  signal raddr         : integer range 0 to W - 1;
  signal waddr         : integer range 0 to W - 1;
  signal slv_raddr      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal slv_waddr      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal we           : std_logic_vector(WE_WIDTH - 1 downto 0);
begin

  slv_raddr <= std_logic_vector(to_unsigned(raddr, ADDR_WIDTH));
  slv_waddr <= std_logic_vector(to_unsigned(waddr, ADDR_WIDTH));

  WE_ASSIGN : process (E) is
    begin
      for i in WE_WIDTH -1 downto 0 loop
        WE(i) <= E;
      end loop;
  end process WE_ASSIGN;
  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        raddr <= 1;
        waddr <= 0;
      else
        if (E = '1') then
          raddr <= add_modulo(raddr, 1, W - 1);
          waddr <= add_modulo(waddr, 1, W - 1);
        end if;
      end if;
    end if;

  end process COUNTER;

  BRAM_SDP_MACRO_INST : BRAM_SDP_MACRO
    generic map (
      -- Target BRAM, "18Kb" or "36Kb"
      BRAM_SIZE => BRAM_SIZE,
      -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
      DEVICE => "7SERIES",
      -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      WRITE_WIDTH => N,
      -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
      READ_WIDTH => N,
      -- Optional output register (0 or 1)
      DO_REG    => 0,
      INIT_FILE => "NONE",
      -- Collision check enable "ALL", "WARNING_ONLY",
      -- "GENERATE_X_ONLY" or "NONE"
      SIM_COLLISION_CHECK => "NONE",
      --  Set/Reset value for port output
      SRVAL => X"000000000000000000",
      -- Specify "READ_FIRST" for same clock or synchronous clocks
      --  Specify "WRITE_FIRST for asynchrononous clocks on ports
      WRITE_MODE => "READ_FIRST",
      INIT       => X"000000000000000000"
    )
    port map (
      -- Output read data port, width defined by READ_WIDTH parameter
      DO => SER_OUTPUT,
      -- Input write data port, width defined by WRITE_WIDTH parameter
      DI => SER_INPUT,
      -- Input read address, width defined by read port depth
      RDADDR => slv_raddr,
      -- 1-bit input read clock
      RDCLK => CLK,
      -- 1-bit input read port enable
      RDEN => E,
      -- 1-bit input read output register enable
      REGCE => '0',
      -- 1-bit input reset
      RST => RST,
      -- Input write enable, width defined by write port depth
      WE => WE,
      -- Input write address, width defined by write port depth
      WRADDR => slv_waddr,
      -- 1-bit input write clock
      WRCLK => CLK,
      -- 1-bit input write port enable
      WREN => E
    );

end architecture BEHAVIORAL;
