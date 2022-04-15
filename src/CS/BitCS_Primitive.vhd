----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: BitCS_Primitive - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Bitserial Compare Swap as an asynchronous variant implemented
-- via primitive.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library UNISIM;
  use UNISIM.VComponents.all;

entity BITCS_PRIMITIVE is
  port (
    A0     : in    std_logic; -- Serial input of operand A
    B0     : in    std_logic; -- Serial input of operand B
    A1     : out   std_logic; -- Serial output of operand A
    B1     : out   std_logic; -- Serial output of operand B
    START  : in    std_logic  -- Start signal marking start of new word.
  );
end entity BITCS_PRIMITIVE;

architecture BEHAVIORAL of BITCS_PRIMITIVE is

  signal state : std_logic_vector(1 downto 0);

begin

  MUX_PRIMITIVE_1 : entity work.mux_2x2_primitive
    port map (
      A0  => A0,
      B0  => B0,
      SEL => state(1),
      A1  => A1,
      B1  => B1
    );

  -- Truthtable of State Machine for BITCS_PRIMITIVE
  -- For more details see ug953
  -- | I5 |    I4 | I3 | I2 | I1 | I0 |     O6 |     O5 | INIT | INIT |
  -- |    | START | Q1 | Q0 |  B0 |  A0 | Q1_n+1 | Q0_n+1 |   O6 |   O5 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     0 |  0 |  0 |  0 |  0 |      0 |      0 |   32 |    0 |
  -- |  1 |     0 |  0 |  0 |  0 |  1 |      0 |      1 |   33 |    1 |
  -- |  1 |     0 |  0 |  0 |  1 |  0 |      1 |      0 |   34 |    2 |
  -- |  1 |     0 |  0 |  0 |  1 |  1 |      0 |      0 |   35 |    3 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     0 |  0 |  1 |  0 |  0 |      0 |      1 |   36 |    4 |
  -- |  1 |     0 |  0 |  1 |  0 |  1 |      0 |      1 |   37 |    5 |
  -- |  1 |     0 |  0 |  1 |  1 |  0 |      0 |      1 |   38 |    6 |
  -- |  1 |     0 |  0 |  1 |  1 |  1 |      0 |      1 |   39 |    7 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     0 |  1 |  0 |  0 |  0 |      1 |      0 |   40 |    8 |
  -- |  1 |     0 |  1 |  0 |  0 |  1 |      1 |      0 |   41 |    9 |
  -- |  1 |     0 |  1 |  0 |  1 |  0 |      1 |      0 |   42 |   10 |
  -- |  1 |     0 |  1 |  0 |  1 |  1 |      1 |      0 |   43 |   11 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     0 |  1 |  1 |  0 |  0 |      0 |      0 |   44 |   12 |
  -- |  1 |     0 |  1 |  1 |  0 |  1 |      0 |      0 |   45 |   13 |
  -- |  1 |     0 |  1 |  1 |  1 |  0 |      0 |      0 |   46 |   14 |
  -- |  1 |     0 |  1 |  1 |  1 |  1 |      0 |      0 |   47 |   15 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     1 |  0 |  0 |  0 |  0 |      0 |      0 |   48 |   16 |
  -- |  1 |     1 |  0 |  0 |  0 |  1 |      0 |      1 |   49 |   17 |
  -- |  1 |     1 |  0 |  0 |  1 |  0 |      1 |      0 |   50 |   18 |
  -- |  1 |     1 |  0 |  0 |  1 |  1 |      0 |      0 |   51 |   19 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     1 |  0 |  1 |  0 |  0 |      0 |      0 |   52 |   20 |
  -- |  1 |     1 |  0 |  1 |  0 |  1 |      0 |      1 |   53 |   21 |
  -- |  1 |     1 |  0 |  1 |  1 |  0 |      1 |      0 |   54 |   22 |
  -- |  1 |     1 |  0 |  1 |  1 |  1 |      0 |      0 |   55 |   23 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     1 |  1 |  0 |  0 |  0 |      0 |      0 |   56 |   24 |
  -- |  1 |     1 |  1 |  0 |  0 |  1 |      0 |      1 |   57 |   25 |
  -- |  1 |     1 |  1 |  0 |  1 |  0 |      1 |      0 |   58 |   26 |
  -- |  1 |     1 |  1 |  0 |  1 |  1 |      0 |      0 |   59 |   27 |
  -- |----+-------+----+----+----+----+--------+--------+------+------|
  -- |  1 |     1 |  1 |  1 |  0 |  0 |      0 |      0 |   60 |   28 |
  -- |  1 |     1 |  1 |  1 |  0 |  1 |      0 |      0 |   61 |   29 |
  -- |  1 |     1 |  1 |  1 |  1 |  0 |      0 |      0 |   62 |   30 |
  -- |  1 |     1 |  1 |  1 |  1 |  1 |      0 |      0 |   63 |   31 |

  -- => O5 = "0000 0010 0010 0010 0000 0000 1111 0010" = X"022200F2"
  -- => O6 = "0000 0100 0100 0100 0000 1111 0000 0100" = X"04440F04"
  -- => INIT = X"04440F04022200F2"

  LUT6_2_INST : entity UNISIM.lut6_2
    generic map (
      INIT => X"04440F04022200F2"
    )
    port map (
      O5 => state(0),
      O6 => state(1),
      I0 => A0,
      I1 => B0,
      I2 => state(0),
      I3 => state(1),
      I4 => START,
      I5 => '1'
    );

end architecture BEHAVIORAL;
