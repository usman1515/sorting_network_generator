----------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Store_Shift_Register_BRAM - Behavioral
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

entity STORE_SHIFT_REGISTER_BRAM is
  generic (
    -- Width of parallel input/ word.
    W  : integer := 8;
    -- Length of subwords to be output at a time.
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                    : in    std_logic;
    -- Synchonous Reset
    RST                    : in    std_logic;
    -- Enable
    E                      : in    std_logic;
    -- Load signal
    STORE                  : in    std_logic;
    -- Write address
    WADDR                  : in    std_logic_vector(integer(ceil(log2(real(W)))) - 1 downto 0);
    -- w-bit parallel input
    SER_INPUT              : in    std_logic_vector(SW - 1 downto 0);
    -- bit-serial output
    PAR_OUTPUT             : out   std_logic_vector(W - 1 downto 0)
  );
end entity STORE_SHIFT_REGISTER_BRAM;

architecture BEHAVIORAL of STORE_SHIFT_REGISTER_BRAM is

  constant BRAM_SIZE                            : string := "18Kb";

  -- Width of the read address of input.
  constant IN_WADDR_WIDTH                       : integer := integer(ceil(log2(real(W))));

  -- Width of the actual write address for BRAM.
  constant WADDR_WIDTH                          : integer := integer(log2(real(18*1024/SW)));                 -- get_addr_width(W, 1);
  signal   slv_waddr                            : std_logic_vector(WADDR_WIDTH - 1 downto 0);

  -- Read address for BRAM.
  constant RADDR_WIDTH                          : integer := 9;
  constant SLV_RADDR                            : std_logic_vector(RADDR_WIDTH - 1 downto 0) := (others => '0');

  constant NUM_BRAM                             : integer := (W + 32 - 1) / 32;  -- Ceil of W/32

  -- Signal selecting and demuxing BRAMS for output
  signal sel                                    : integer range 0 to NUM_BRAM - 1;

  -- Combined input vector of BRAMS.
  signal ser_input_i                            : std_logic_vector(NUM_BRAM * SW - 1 downto 0);

  -- Delayed data and store signals to fit timing of BRAM.
  signal store_delayed                          : std_logic;
  signal data_delayed                           : std_logic_vector(SW - 1 downto 0);

  type open_do_t is array(0 to NUM_BRAM - 1) of std_logic_vector(32 - W - 1 downto 0);

  signal open_do                                : open_do_t;

begin

  SET_SEL : process (WADDR) is
  begin

    sel <= to_integer(shift_right(unsigned(WADDR), 5));

  end process SET_SEL;

  SET_WADDR : process (WADDR) is
  begin

    -- Since we read out only 32 bits with each address corresponding to a
    -- bit, we only need the lower 5 bits.
    if (IN_WADDR_WIDTH > 5) then
      slv_waddr(4 downto 0)               <= WADDR(4 downto 0);
      slv_waddr(WADDR_WIDTH - 1 downto 5) <= (others => '0');
    else
      slv_waddr(IN_WADDR_WIDTH - 1  downto 0)          <= WADDR(IN_WADDR_WIDTH - 1 downto 0);
      slv_waddr(WADDR_WIDTH - 1 downto IN_WADDR_WIDTH) <= (others => '0');
    end if;

  end process SET_WADDR;

  SET_BUFFER : process (CLK) is
  begin

    -- Synchonously set buffer and load_delayed.
    if (rising_edge(CLK)) then
      if (E = '1') then
        store_delayed   <= STORE;
        data_delayed <= SER_INPUT;
      end if;
    end if;

  end process SET_BUFFER;

  BRAMS : for i in 0 to NUM_BRAM - 1 generate

    BRAM_SDP_MACRO_INST : entity unimacro.bram_sdp_macro
      generic map (
        BRAM_SIZE   => "18Kb",
        DEVICE      => "7SERIES",
        WRITE_WIDTH => SW,
        READ_WIDTH  => 32,
        DO_REG      => 1,
        INIT_FILE   => "NONE",
        WRITE_MODE  => "READ_FIRST",
        -- Collision check enable "ALL", "WARNING_ONLY",
        -- "GENERATE_X_ONLY" or "NONE"
        SIM_COLLISION_CHECK => "ALL"
      )
      port map (
        RDCLK               => CLK,
        WRCLK               => CLK,
        RST                 => RST,
        DI                  => data_delayed,
        WRADDR              => slv_waddr,
        WE                  => "1",
        WREN                => E,
        DO(W - 1 downto 0)  => PAR_OUTPUT,
        DO(32 - 1 downto W) => open_do(i),
        RDADDR              => SLV_RADDR,
        RDEN                => store_delayed,
        REGCE               => '1'
      );

  end generate BRAMS;

end architecture BEHAVIORAL;
