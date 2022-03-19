----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: MUX_Sim - Behavioral
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
-- arithmetic functions with Signed or integer values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ShiftRegisters_Sim is
--  Port ( );
  generic(
    w : integer := 8
    );
end ShiftRegisters_Sim;

architecture Behavioral of ShiftRegisters_Sim is

  component LoadShiftRegister is
    generic (
      w : integer);
    port (
      CLK        : in  std_logic;
      input      : in  std_logic_vector(w-1 downto 0);
      E          : in  std_logic;
      LD         : in  std_logic;
      ser_output : out std_logic);
  end component LoadShiftRegister;

  component StoreShiftRegister is
    generic (
      w : integer);
    port (
      CLK       : in  std_logic;
      E         : in  std_logic;
      ser_input : in  std_logic;
      ST        : in  std_logic;
      output    : out std_logic_vector(w-1 downto 0));
  end component StoreShiftRegister;

  constant ckTime : time := 10 ns;

  signal clock  : std_logic;
  signal A      : std_logic_vector(w-1 downto 0) := (others => '0');
  signal B      : std_logic_vector(w-1 downto 0) := (others => '0');
  signal LD     : std_logic_vector(0 downto 0)   := "0";
  signal ST     : std_logic_vector(0 downto 0)   := "0";
  signal E      : std_logic                      := '0';
  signal serial : std_logic                      := '0';

begin

  clock_process : process
  begin
    clock <= '0';
    wait for ckTime/2;
    clock <= '1';
    wait for ckTime/2;
  end process;

  LoadShiftRegister_1 : LoadShiftRegister
    generic map (
      w => w)
    port map (
      CLK        => clock,
      LD         => LD(0),
      E          => E,
      input      => A,
      ser_output => serial);

  StoreShiftRegister_1 : StoreShiftRegister
    generic map (
      w => w)
    port map (
      CLK       => clock,
      ST        => ST(0),
      E         => E,
      ser_input => serial,
      output    => B);

  test_process : process
  begin


    wait for ckTime;
    A  <= "11001011";
    LD <= "1";
    E  <= '1';
    for i in 0 to w-3 loop
      wait for ckTime;
      LD <= "0";
    end loop;
    E  <= '0';
    wait for ckTime*2;
    E  <= '1';
    wait for ckTime*2;
    ST <= "1";
    wait for ckTime;
    ST <= "0";
    assert (A = B) report "Mismatch:: " &
      " A= " & integer'image(to_integer(unsigned(A))) &
      " B= " & integer'image(to_integer(unsigned(B))) &
      " Expectation= A=B";

    wait;

  end process;

end Behavioral;
