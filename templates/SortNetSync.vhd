----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: SortNetSync Template
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity {top_name} is
  generic (
    W     : integer := {bit_width};
    DEPTH : integer := {net_depth};
    N     : integer := {num_inputs};
    M     : integer := {num_outputs}
  );
  port (
    CLK      : in    std_logic;
    E        : in    std_logic;
    RST      : in    std_logic;
    INPUT    : in    SLVArray(N - 1 downto 0)(W - 1 downto 0);
    OUTPUT   : out   SLVArray(M - 1 downto 0)(W - 1 downto 0)
  );
end entity {top_name};

architecture BEHAVIORAL of {top_name} is

  type wire_t is array (N - 1 downto 0) of std_logic_vector(DEPTH downto 0);

  signal wire     : wire_t;

  signal start    : std_logic_vector(DEPTH downto 0);

begin

  CYCLE_TIMER_1 : entity work.cycle_timer
    generic map (
      W => W
    )
    port map (
      CLK   => CLK,
      RST   => RST,
      E     => E,
      START => start(0)
    );

  -- STARTDELAY------------------------------------------------------------------
  -- Generates a shift register for delaying the starting signal for each sorter
  -- stage.
  -------------------------------------------------------------------------------
  STARTDELAY : process(CLK) is
  begin

    if (rising_edge(CLK)) then
      start(start'high downto start'low + 1) <= start(start'high - 1 downto start'low);
    end if;

  end process STARTDELAY;

  {instances}

end architecture BEHAVIORAL;
