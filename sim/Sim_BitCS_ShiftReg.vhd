----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_BitCS_ShiftReg - Behavioral
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

entity Sim_BitCS_ShiftReg is
  generic(
    w : integer := 8
    );
end Sim_BitCS_ShiftReg;

architecture Behavioral of Sim_BitCS_ShiftReg is

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
      E          : in  std_logic;
      LD         : in  std_logic;
      input      : in  std_logic_vector(w-1 downto 0);
      ser_output : out std_logic);
  end component LoadShiftRegister;
  component StoreShiftRegister is
    generic (
      w : integer);
    port (
      CLK       : in  std_logic;
      E         : in  std_logic;
      ST        : in  std_logic;
      ser_input : in  std_logic;
      output    : out std_logic_vector(w-1 downto 0));
  end component StoreShiftRegister;


  constant ckTime : time := 10 ns;

  signal CLK   : std_logic;
  signal sin0  : std_logic := '0';
  signal sin1  : std_logic := '0';
  signal sout0 : std_logic := '0';
  signal sout1 : std_logic := '0';
  signal S     : std_logic := '0';

  signal E  : std_logic := '0';
  signal LD : std_logic := '0';
  signal ST : std_logic := '0';

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
    port map(sin0, sin1, sout0, sout1, S);

  LoadShiftRegister_1 : LoadShiftRegister
    generic map (
      w => w)
    port map (
      CLK        => CLK,
      E          => E,
      LD         => LD,
      input      => A,
      ser_output => sin0);
  LoadShiftRegister_2 : LoadShiftRegister
    generic map (
      w => w)
    port map (
      CLK        => CLK,
      E          => E,
      LD         => LD,
      input      => B,
      ser_output => sin1);

  StoreShiftRegister_1 : StoreShiftRegister
    generic map (
      w => w)
    port map (
      CLK       => CLK,
      E         => E,
      ST        => ST,
      ser_input => sout0,
      output    => C);
  StoreShiftRegister_2 : StoreShiftRegister
    generic map (
      w => w)
    port map (
      CLK       => CLK,
      E         => E,
      ST        => ST,
      ser_input => sout1,
      output    => D);

  test_process : process

  begin

    larger_value  <= "10110110";
    smaller_value <= "10100111";
    wait for ckTime/2 + 1 ps;

    E <= '1';

    A <= larger_value;
    B <= smaller_value;

    for i in 0 to w-1 loop
      wait for ckTime;
      if i = 0 then
        LD <= '1';
        S  <= '1';
        ST <= '1';
      else
        LD <= '0';
        S  <= '0';
        ST <= '0';
      end if;
    end loop;

    A <= smaller_value;
    B <= larger_value;

    for i in 0 to w-1 loop
      wait for ckTime;
      if i = 0 then
        LD <= '1';
        S  <= '1';
        ST <= '1';
      else
        LD <= '0';
        S  <= '0';
        ST <= '0';
      end if;
      if i = 1 then
        assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
          " A= " & integer'image(to_integer(unsigned(larger_value))) &
          " B= " & integer'image(to_integer(unsigned(smaller_value))) &
          " C= " & integer'image(to_integer(unsigned(C))) &
          " D= " & integer'image(to_integer(unsigned(D))) &
          " Expectation A=C and B=D";
      end if;
    end loop;


    for i in 0 to w-1 loop
      wait for ckTime;
      if i = 0 then
        LD <= '1';
        S  <= '1';
        ST <= '1';
      else
        LD <= '0';
        S  <= '0';
        ST <= '0';
      end if;
      if i = 1 then
        assert ((larger_value = C) and (smaller_value = D)) report "Mismatch:: " &
          " A= " & integer'image(to_integer(unsigned(smaller_value))) &
          " B= " & integer'image(to_integer(unsigned(larger_value))) &
          " C= " & integer'image(to_integer(unsigned(C))) &
          " D= " & integer'image(to_integer(unsigned(D))) &
          " Expectation A=D and B=C";
      end if;
    end loop;

    wait;

  end process;

end Behavioral;
