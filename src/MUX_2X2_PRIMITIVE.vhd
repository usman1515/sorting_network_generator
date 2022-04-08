----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: MUX_2x2_PRIMITIVE - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Asynchronous 2 to 2 MUX as primitive.
--
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library UNISIM;
  use UNISIM.vcomponents.all;

-- LUT6_2: 6-input 2 output Look-Up Table
-- 7 Series
-- Xilinx HDL Language Template, version 2021.2

entity MUX_2X2_PRIMITIVE is
  port (
    A0   : in    std_logic;
    B0   : in    std_logic;
    SEL  : in    std_logic;
    A1   : out   std_logic;
    B1   : out   std_logic
  );
end entity MUX_2X2_PRIMITIVE;

architecture STRUCTURAL of MUX_2X2_PRIMITIVE is

begin

  -- See ug953 for details
  -- | I5 | I2 | I1 | I0 | INIT | O6 | INIT | O5 |
  -- |----+----+----+----+------+----+------+----|
  -- |  1 |  0 |  0 |  0 |   32 |  0 |    0 |  0 |
  -- |  1 |  0 |  0 |  1 |   33 |  0 |    1 |  1 |
  -- |  1 |  0 |  1 |  0 |   34 |  1 |    2 |  0 |
  -- |  1 |  0 |  1 |  1 |   35 |  1 |    3 |  1 |
  -- |  1 |  1 |  0 |  0 |   36 |  0 |    4 |  0 |
  -- |  1 |  1 |  0 |  1 |   37 |  1 |    5 |  0 |
  -- |  1 |  1 |  1 |  0 |   38 |  0 |    6 |  1 |
  -- |  1 |  1 |  1 |  1 |   39 |  1 |    7 |  1 |

  -- => O5 = "11001010" = X"CA"
  -- => O6 = "10101100" = X"AC"
  -- => INIT = X"000000AC000000CA"

  LUT6_2_INST : entity UNISIM.lut6_2
    generic map (
      INIT => X"000000AC000000CA"
    )
    port map (
      O6 => B1,
      O5 => A1,
      I0 => A0,
      -- LUT input (1-bit)
      I1 => B0,
      -- LUT input (1-bit)
      I2 => SEL,
      -- LUT input (1-bit)
      I3 => '0',
      -- LUT input (1-bit)
      I4 => '0',
      -- LUT input (1-bit)
      I5 => '1'
      -- LUT input (1-bit)
    );

  -- End of LUT6_2_inst instantiation

end architecture STRUCTURAL;
