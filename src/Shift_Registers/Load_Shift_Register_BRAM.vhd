----------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Load_Shift_Register_BRAM - Behavioral
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

entity LOAD_SHIFT_REGISTER_BRAM is
  generic (
    -- Width of parallel input/ word.
    W  : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
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
    -- Read address
    RADDR                 : in    std_logic_vector(integer(ceil(log2(real(W)))) - 1 downto 0);
    -- w-bit parallel input
    PAR_INPUT             : in    std_logic_vector(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   std_logic_vector(SW - 1 downto 0)
  );
end entity LOAD_SHIFT_REGISTER_BRAM;

architecture BEHAVIORAL of LOAD_SHIFT_REGISTER_BRAM is

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

  constant BRAM_SIZE              : string := "18Kb";

  -- Width of the read address of input.
  constant IN_RADDR_WIDTH         : integer := integer(ceil(log2(real(W))));
  -- Width of the actual read address for BRAM.
  constant RADDR_WIDTH            : integer := integer(log2(real(18 * 1024 / SW)));
  -- Read address for BRAM.
  signal slv_raddr                : std_logic_vector(RADDR_WIDTH - 1 downto 0);

  -- Each BRAM is only responsible for a maximum number of 32 bits.
  -- if more than 32 bits are required, additional BRAMs will be instantiated.
  constant NUM_BRAM               : integer := (W + 32 - 1) / 32; -- Ceil of W/32

  constant WADDR_WIDTH            : integer := 9;                 -- get_addr_width(W, 1);
  constant SLV_WADDR              : std_logic_vector(WADDR_WIDTH - 1 downto 0) := (others => '0');
  signal   we_i                   : std_logic_vector(4 - 1 downto 0);
  -- Signal selecting and demuxing BRAMS for output
  signal sel                      : integer range 0 to NUM_BRAM - 1;
  -- Combined output vector of BRAMS.
  signal ser_output_i             : std_logic_vector(NUM_BRAM * SW - 1 downto 0);
  -- Combined output vector of BRAMS.
  signal par_input_i              : std_logic_vector(NUM_BRAM * 32 - 1 downto 0);
  -- Signals to handle the write to read delays.
  -- Keeps the second sub-word buffered.
  signal buffer_i                 : std_logic_vector(SW - 1 downto 0);
  -- Delays the load signal by one cycle.
  signal load_delayed             : std_logic;

begin

  SET_WE : process (LOAD) is
  begin

    if (LOAD = '1') then
      we_i <= "1111";
    else
      we_i <= "0000";
    end if;

  end process SET_WE;

  SET_SEL : process (RADDR) is
  begin

    sel <= to_integer(shift_right(unsigned(RADDR), 5));

  end process SET_SEL;

  SET_RADDR : process (RADDR) is
  begin

    -- Since we read out only 32 bits with each address corresponding to a
    -- bit, we only need the lower 5 bits.
    if (IN_RADDR_WIDTH > 5) then
      slv_raddr(4 downto 0)               <= RADDR(4 downto 0);
      slv_raddr(RADDR_WIDTH - 1 downto 5) <= (others => '0');
    else
      slv_raddr(IN_RADDR_WIDTH - 1  downto 0)          <= RADDR(IN_RADDR_WIDTH - 1 downto 0);
      slv_raddr(RADDR_WIDTH - 1 downto IN_RADDR_WIDTH) <= (others => '0');
    end if;

  end process SET_RADDR;

  SET_MSB_BUFFER : process (CLK) is
  begin

    -- Synchonously set buffer and load_delayed.
    if (rising_edge(CLK)) then
      load_delayed <= LOAD;
      buffer_i     <= PAR_INPUT(W - SW - 1 downto W - SW * 2);
    end if;

  end process SET_MSB_BUFFER;

  SET_PAR_INPUT : process (PAR_INPUT) is
  begin

    par_input_i(W - 1 downto 0)             <= PAR_INPUT;
    par_input_i(NUM_BRAM * 32 - 1 downto W) <= (others => '0');

  end process SET_PAR_INPUT;

  --  BRAM_OUT : process (CLK) is
  BRAM_OUT : process (RST, LOAD, PAR_INPUT, load_delayed, buffer_i, ser_output_i, sel) is
  begin

    --   if (rising_edge(CLK)) then
    if (RST ='1') then
      -- Reset
      SER_OUTPUT <= (others => '0');
    else
      if (LOAD = '1') then
        -- Output the first subword immediatly
        SER_OUTPUT <= PAR_INPUT(W - 1 downto W - SW);
      else
        if (load_delayed = '1') then
          -- Output the buffered second subword.
          SER_OUTPUT <= buffer_i;
        else
          -- Only after two cycles, the output of the BRAM is valid.
          -- Demultiplex output of BRAMS into SER_OUTPUT.
          SER_OUTPUT <= ser_output_i((sel + 1) * SW - 1 downto sel * SW);
        end if;
      end if;
    end if;

    --    end if;

  end process BRAM_OUT;

  BRAMS : for i in 0 to NUM_BRAM - 1 generate

    BRAM_SDP_MACRO_INST : BRAM_SDP_MACRO
      generic map (
        BRAM_SIZE   => "18Kb",
        DEVICE      => "7SERIES",
        WRITE_WIDTH => 32,
        READ_WIDTH  => SW,
        DO_REG      => 0,
        INIT_FILE   => "NONE",
        WRITE_MODE  => "READ_FIRST",
        -- Collision check enable "ALL", "WARNING_ONLY",
        -- "GENERATE_X_ONLY" or "NONE"
        SIM_COLLISION_CHECK => "ALL"
      )
      port map (
        RDCLK  => CLK,
        WRCLK  => CLK,
        RST    => RST,
        DI     => par_input_i(32* (i + 1) - 1 downto 32*i),
        WRADDR => SLV_WADDR,
        WE     => we_i,
        WREN   => E,
        DO     => ser_output_i((i + 1)*SW - 1 downto i*SW),
        RDADDR => slv_raddr,
        RDEN   => E,
        REGCE  => '0'
      );

  end generate BRAMS;

end architecture BEHAVIORAL;
