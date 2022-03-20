-------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: BitCS_SmallNet_Sim - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity BitCS_SmallNet_Sim is
  generic(
    w : integer := 8
    );
end BitCS_SmallNet_Sim;

architecture Behavioral of BitCS_SmallNet_Sim is

  component BitCS is
    port (
      a : in std_logic;
      b : in std_logic;
      c : out std_logic;
      d : out std_logic;
      S : in std_logic);
  end component BitCS;
  component LoadShiftRegister is
    generic (
      w : integer);
    port (
      CLK : in std_logic;
      E : in std_logic;
      LD : in std_logic;
      input : in std_logic_vector(w-1 downto 0);
      ser_output : out std_logic);
  end component LoadShiftRegister;
  component StoreShiftRegister is
    generic (
      w : integer);
    port (
      CLK : in std_logic;
      E : in std_logic;
      ST : in std_logic;
      ser_input : in std_logic;
      output : out std_logic_vector(w-1 downto 0));
  end component StoreShiftRegister;
  component CycleTimer is
    generic (
      w : integer);
    port (
      CLK : in std_logic;
      R : in std_logic;
      E : in std_logic;
      LD : out std_logic;
      S : out std_logic;
      ST : out std_logic);
  end component CycleTimer;

  constant ckTime : time := 10 ns;

  signal CLK : std_logic;

  type GRID2D is array (3 downto 0) of std_logic_vector(3 downto 0);

  signal wire : GRID2D := (others => (others => '0'));


  signal LD : std_logic := '0';
  signal S : std_logic := '0';
  signal ST : std_logic := '0';
  signal E : std_logic := '0';
  signal R : std_logic := '0';

  type MEMBLOCK is array (3 downto 0) of std_logic_vector(w-1 downto 0);
  signal A : MEMBLOCK := (X"5C", X"2B", X"A8", X"F2");
  signal B : MEMBLOCK := (others => (others => '0'));

begin

  CLK_process : process
  begin
    CLK <= '0';
    wait for ckTime/2;
    CLK <= '1';
    wait for ckTime/2;
  end process;

  InputShift :
  for i in 0 to 3 generate
    LSR : LoadShiftRegister
          generic map (
            w => w)
          port map (
            CLK => CLK,
            E => E,
            LD => LD,
            input => A(i),
            ser_output => wire(0)(i));
  end generate InputShift;

  OutputShift :
  for i in 0 to 3 generate
    SSR : StoreShiftRegister
      generic map (
        w => w)
      port map (
        CLK => CLK,
        E => E,
        ST => ST,
        output => B(i),
        ser_input => wire(3)(i));
  end generate OutputShift;

  BitCS_0 : entity work.BitCS
    port map (
    a => wire(0)(1),
    b => wire(0)(0),
    c => wire(1)(1),
    d => wire(1)(0),
    S => S);

  BitCS_1 : entity work.BitCS
    port map (
    a => wire(0)(3),
    b => wire(0)(2),
    c => wire(1)(3),
    d => wire(1)(2),
    S => S);

  BitCS_2 : entity work.BitCS
    port map (
    a => wire(1)(3),
    b => wire(1)(1),
    c => wire(2)(3),
    d => wire(2)(1),
    S => S);

  BitCS_3 : entity work.BitCS
    port map (
    a => wire(1)(2),
    b => wire(1)(0),
    c => wire(2)(2),
    d => wire(2)(0),
    S => S);

  BitCS_4 : entity work.BitCS
    port map (
    a => wire(2)(2),
    b => wire(2)(1),
    c => wire(3)(2),
    d => wire(3)(1),
    S => S);

  wire(3)(3) <= wire(2)(3) ;
  wire(3)(0) <= wire(2)(0) ;

  CycleTimer_1 : CycleTimer
    generic map (
      w => w)
    port map (
      CLK => CLK,
      R => R,
      E => E,
      LD => LD,
      S => S,
      ST => ST);
  test_process : process

  begin

    E <= '0';
    wait for ckTime/2;
    R <= '1';
    wait for ckTime;
    R <= '0';
    E <= '1';
    wait for (w-1)*ckTime;
    -- assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
    --   " A= " & integer'image(to_integer(unsigned(larger_value))) &
    --   " B= " & integer'image(to_integer(unsigned(smaller_value))) &
    --   " C= " & integer'image(to_integer(unsigned(C))) &
    --   " D= " & integer'image(to_integer(unsigned(D))) &
    --   " Expectation A=C and B=D";


    -- A <= X"a6";
    -- B <= X"b7";

    -- wait for (w-1)*ckTime;
    -- assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
    --   " A= " & integer'image(to_integer(unsigned(smaller_value))) &
    --   " B= " & integer'image(to_integer(unsigned(larger_value))) &
    --   " C= " & integer'image(to_integer(unsigned(C))) &
    --   " D= " & integer'image(to_integer(unsigned(D))) &
    --   " Expectation A=D and B=C";
    wait;

  end process;

end Behavioral;
