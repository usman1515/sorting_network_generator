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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity BitCS is
  port (
    a     : in  std_logic;
    b     : in  std_logic;
    c     : out std_logic;
    d     : out std_logic;
    start : in  std_logic);
end BitCS;


architecture Behavioral of BitCS is

  component MUX_PRIMITIVE is
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      c   : out std_logic;
      d   : out std_logic);
  end component MUX_PRIMITIVE;

  signal state : std_logic_vector(1 downto 0)  := "00";

begin
  
-- Truthtable of State Machine for BitCS
-- For more details see ug953
-- | I5 |    I4 | I3 | I2 | I1 | I0 |     O6 |     O5 | INIT | INIT |
-- |    | start | Q1 | Q0 |  b |  a | Q1_n+1 | Q0_n+1 |   O6 |   O5 |
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

  LUT6_2_inst : LUT6_2
    generic map (
      INIT => X"04440F04022200F2")      -- Specify LUT Contents
    port map (
      O5 => state(0),                       -- 5-LUT output (1-bit)
      O6 => state(1),                       -- 6/5-LUT output (1-bit)
      I0 => a,
      I1 => b,
      I2 => state(0),
      I3 => state(1),
      I4 => start,
      I5 => '1'
      );

outMUX : MUX_PRIMITIVE
    port map(a, b, state(1), c, d);


end Behavioral;
