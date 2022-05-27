---------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Register_DSP - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: DSP configured do perform concatenation in order to use block
-- as Register.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library UNISIM;
  use UNISIM.vcomponents.all;

library UNIMACRO;
  use UNIMACRO.vcomponents.all;

entity REGISTER_DSP is
  generic (
    -- Number of registers used
    NUM_INPUT : integer := 48;
    -- Number of registers per input
    REG_PER_INPUT : integer := 1
  );
  port (
    -- System Clock
    CLK        : in    std_logic;
    -- Reset
    RST        : in    std_logic;
    -- Enable
    E          : in    std_logic;
    -- bit serial input
    REG_INPUT  : in    std_logic_vector(NUM_INPUT - 1 downto 0);
    -- bit-serial output
    REG_OUTPUT : out   std_logic_vector(NUM_INPUT - 1 downto 0)
  );
end entity REGISTER_DSP;

architecture BEHAVIORAL of REGISTER_DSP is

  signal open_carryout : std_logic;
  constant zero_b        : std_logic_vector(NUM_INPUT - 1 downto 0) := (others => '0');

begin

  -- ADDSUB_MACRO: Variable width & latency - Adder / Subtrator implemented in a DSP48E
  --               Artix-7
  -- Xilinx HDL Language Template, version 2021.2

  ADDSUB_MACRO_INST : ADDSUB_MACRO
    generic map (
      -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
      DEVICE => "7SERIES",
      -- Desired clock cycle latency, 0-2
      LATENCY => REG_PER_INPUT,
      -- Input / Output bus width, 1-48
      WIDTH => NUM_INPUT
    )
    port map (
      -- 1-bit carry-out output signal
      CARRYOUT => open_carryout,
      -- Add/sub result output, width defined by WIDTH generic
      RESULT => REG_OUTPUT,
      -- Input A bus, width defined by WIDTH generic
      A => REG_INPUT,
      -- 1-bit add/sub input, high selects add, low selects subtract
      ADD_SUB => '1',
      -- Input B bus, width defined by WIDTH generic
      B => zero_b,
      -- 1-bit carry-in input
      CARRYIN => '0',
      -- 1-bit clock enable input
      CE => '1',
      -- 1-bit clock input
      CLK => CLK,
      -- 1-bit active high synchronous reset
      RST => RST
    );

  -- End of ADDSUB_MACRO_inst instantiation

end architecture BEHAVIORAL;
