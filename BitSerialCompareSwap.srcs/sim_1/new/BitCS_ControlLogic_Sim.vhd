----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: BitCS_ControlLogic_Sim - Behavioral
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

entity BitCS_ControlLogic_Sim is
  generic(
    w : integer := 8
    );
end BitCS_ControlLogic_Sim;

architecture Behavioral of BitCS_ControlLogic_Sim is

  component BitCS is
    port (
      a : in  std_logic;
      b : in  std_logic;
      c : out std_logic;
      d : out std_logic;
      S : in  std_logic);
  end component BitCS;
  component LoadShiftRegister is
    generic (
      w : integer);
    port (
      CLK        : in  std_logic;
      input      : in  std_logic_vector(w-1 downto 0);
      LD         : in  std_logic;
      ser_output : out std_logic);
  end component LoadShiftRegister;
  component StoreShiftRegister is
    generic (
      w : integer);
    port (
      CLK       : in  std_logic;
      ser_input : in  std_logic;
      ST        : in  std_logic;
      output    : out std_logic_vector(w-1 downto 0));
  end component StoreShiftRegister;
  component CycleTimer is
    generic (
      w : integer);
    port (
      CLK : in  std_logic;
      R   : in  std_logic;
      E   : in  std_logic;
      LD  : out std_logic;
      S   : out std_logic;
      ST  : out std_logic);
  end component CycleTimer;

  constant ckTime : time := 10 ns;

  signal CLK : std_logic;

  signal in0  : std_logic := '0';
  signal in1  : std_logic := '0';
  signal out0 : std_logic := '0';
  signal out1 : std_logic := '0';

  signal LD : std_logic := '0';
  signal S  : std_logic := '0';
  signal ST : std_logic := '0';
  signal E  : std_logic := '0';
  signal R  : std_logic := '0';


  signal A : std_logic_vector(w-1 downto 0) := (others => '0');
  signal B : std_logic_vector(w-1 downto 0) := (others => '0');
  signal C : std_logic_vector(w-1 downto 0) := (others => '0');
  signal D : std_logic_vector(w-1 downto 0) := (others => '0');

  signal larger_value  : std_logic_vector(w-1 downto 0) := (others => '0');
  signal smaller_value : std_logic_vector(w-1 downto 0) := (others => '0');
begin

  CLK_process : process
  begin
    CLK <= '0';
    wait for ckTime/2;
    CLK <= '1';
    wait for ckTime/2;
  end process;

  uut_0 : BitCS
    port map(in0, in1, out0, out1, S);

  CycleTimer_1 : entity work.CycleTimer
    generic map (
      w => w)
    port map (
      CLK => CLK,
      R   => R,
      E   => E,
      LD  => LD,
      S   => S,
      ST  => ST);

  LoadShiftRegister_1 : LoadShiftRegister
    generic map (
      w => w)
    port map (
      CLK        => CLK,
      input      => A,
      LD         => LD,
      ser_output => in0);
  LoadShiftRegister_2 : LoadShiftRegister
    generic map (
      w => w)
    port map (
      CLK        => CLK,
      input      => B,
      LD         => LD,
      ser_output => in1);

  StoreShiftRegister_1 : StoreShiftRegister
    generic map (
      w => w)
    port map (
      CLK       => CLK,
      ser_input => out0,
      ST        => ST,
      output    => C);
  StoreShiftRegister_2 : StoreShiftRegister
    generic map (
      w => w)
    port map (
      CLK       => CLK,
      ser_input => out1,
      ST        => ST,
      output    => D);

  test_process : process

  begin

    larger_value  <= "10110110";
    smaller_value <= "10100111";
    E <= '0';
    wait for ckTime/2;
    R <= '1';
    A <= larger_value;
    B <= smaller_value;
    wait for ckTime;
    R <= '0';
    E <= '1';
    wait for (w-1)*ckTime;
    assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
      " A= " & integer'image(to_integer(unsigned(larger_value))) &
      " B= " & integer'image(to_integer(unsigned(smaller_value))) &
      " C= " & integer'image(to_integer(unsigned(C))) &
      " D= " & integer'image(to_integer(unsigned(D))) &
      " Expectation A=C and B=D";


    A <= smaller_value;
    B <= larger_value;

    wait for (w-1)*ckTime;
    assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
      " A= " & integer'image(to_integer(unsigned(smaller_value))) &
      " B= " & integer'image(to_integer(unsigned(larger_value))) &
      " C= " & integer'image(to_integer(unsigned(C))) &
      " D= " & integer'image(to_integer(unsigned(D))) &
      " Expectation A=D and B=C";
    wait;

  end process;

end Behavioral;
