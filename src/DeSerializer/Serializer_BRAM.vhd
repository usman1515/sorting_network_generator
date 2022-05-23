----------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Serializer_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Serializer Component using an array to infer BRAM.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

library work;
  use work.CustomTypes.all;

library UNISIM;
  use UNISIM.vcomponents.all;

library UNIMACRO;
  use unimacro.Vcomponents.all;

entity SERIALIZER_BRAM is
  generic (
    -- Width of parallel input/ word.
    W : integer := 8
  );
  port (
    -- System Clock
    CLK                   : in    std_logic;
    -- Synchonous Reset
    RST                   : in    std_logic;
    -- Enable
    E                     : in    std_logic;
    -- Load signal
    LOAD                  : in    std_logic;
    -- w-bit parallel input
    PAR_INPUT             : in    std_logic_vector(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   std_logic
  );
end entity SERIALIZER_BRAM;

architecture BEHAVIORAL of SERIALIZER_BRAM is

  function sub_hold (a : integer; b : integer) return integer is
  begin

    if (b > a) then
      return 0;
    else
      return a - b;
    end if;

  end function sub_hold;

  function add_modulo (a : integer; b : integer; max : integer) return integer is
  begin

    return (a + b) mod (max + 1);

  end function add_modulo;

  constant BRAM_SIZE       : string := "18Kb";
  constant RADDR_WIDTH     : integer := 14; -- get_addr_width(W, 1);
  constant WADDR_WIDTH     : integer := 9;  -- get_addr_width(W, 1);

  -- WARNING: No checks prevent a address depth exceeding the allowed bounds of
  -- the BRAM block !

  constant WADDR           : integer range 0 to W - 1 := 0;

  signal raddr             : integer range 0 to W - 1;
  signal slv_raddr         : std_logic_vector(RADDR_WIDTH - 1 downto 0);
  signal slv_waddr         : std_logic_vector(WADDR_WIDTH - 1 downto 0);
  signal ser_output_i      : std_logic_vector(0 downto 0);

begin

  slv_raddr <= std_logic_vector(to_unsigned(raddr, RADDR_WIDTH));
  slv_waddr <= std_logic_vector(to_unsigned(WADDR, WADDR_WIDTH));

  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or LOAD = '1') then
        raddr <= 0;
      else
        if (E = '1') then
          raddr <= add_modulo(raddr, 1, W - 1);
        end if;
      end if;
    end if;

  end process COUNTER;

  BRAM_OUT : process (RST, LOAD, PAR_INPUT, ser_output_i) is
  begin

    if (RST ='1') then
      SER_OUTPUT <= '0';
    else
      if (LOAD = '1') then
        SER_OUTPUT <= PAR_INPUT(W - 1);
      else
        SER_OUTPUT <= ser_output_i(0);
      end if;
    end if;

  end process BRAM_OUT;

  BRAM_SDP_MACRO_INST : BRAM_SDP_MACRO
    generic map (
      BRAM_SIZE   => "18Kb",
      DEVICE      => "7SERIES",
      WRITE_WIDTH => 32,
      READ_WIDTH  => 1,
      DO_REG      => 0,
      INIT_FILE   => "NONE",
      WRITE_MODE  => "READ_FIRST",
      -- Collision check enable "ALL", "WARNING_ONLY",
      -- "GENERATE_X_ONLY" or "NONE"
      SIM_COLLISION_CHECK => "NONE"
    )
    port map (
      RDCLK               => CLK,
      WRCLK               => CLK,
      RST                 => RST,
      DI(W - 1 downto 0)  => PAR_INPUT,
      DI(32 - 1 downto W) => (others => '0'),
      WRADDR              => slv_waddr,
      WE                  => "1111",
      WREN                => E,
      DO                  => ser_output_i,
      RDADDR              => slv_raddr,
      RDEN                => E,
      REGCE               => '0'
    );

end architecture BEHAVIORAL;
