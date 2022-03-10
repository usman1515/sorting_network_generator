----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: BitCS - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.vcomponents.all;
-- LUT6_2: 6-input 2 output Look-Up Table
-- 7 Series
-- Xilinx HDL Language Template, version 2021.2
entity MUX_PRIMITIVE is
  port (
    a   : in std_logic;
    b   : in std_logic;
    sel : in std_logic;

    c : out std_logic;
    d : out std_logic);
end MUX_PRIMITIVE;

architecture Behavioral of MUX_PRIMITIVE is
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

  LUT6_2_inst : LUT6_2
    generic map (
      INIT => X"000000AC000000CA")      -- Specify LUT Contents
    port map (
      O6 => d,                          -- 6/5-LUT output (1-bit)
      O5 => c,                          -- 5-LUT output (1-bit)
      I0 => a,
      -- LUT input (1-bit)
      I1 => b,
      -- LUT input (1-bit)
      I2 => sel,
      -- LUT input (1-bit)
      I3 => '0',
      -- LUT input (1-bit)
      I4 => '0',
      -- LUT input (1-bit)
      I5 => '1'
     -- LUT input (1-bit)
      );
-- End of LUT6_2_inst instantiation
end architecture Behavioral;
