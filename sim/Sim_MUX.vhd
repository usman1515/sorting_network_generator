----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name: 
-- Module Name: Sim_MUX - Behavioral
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

entity Sim_MUX is
--  Port ( );
end Sim_MUX;

architecture Behavioral of Sim_MUX is

  constant ckTime : time := 10 ns;

  signal clock   : std_logic;
  signal input   : std_logic_vector(1 downto 0) := "00";
  signal sel_s   : std_logic_vector(0 downto 0) := "0";
  signal output0 : std_logic_vector(1 downto 0);
  signal output1 : std_logic_vector(1 downto 0);
  component MUX
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      c   : out std_logic;
      d   : out std_logic
      );
  end component;

  component MUX_PRIMITIVE
    port (
      a   : in  std_logic;
      b   : in  std_logic;
      sel : in  std_logic;
      c   : out std_logic;
      d   : out std_logic
      );
  end component;
begin

  clock_process : process
  begin
    clock <= '0';
    wait for ckTime/2;
    clock <= '1';
    wait for ckTime/2;
  end process;

  uut_0 : MUX
    port map(input(0), input(1), sel_s(0), output0(0), output0(1));

  uut_1 : MUX_PRIMITIVE
    port map(input(0), input(1), sel_s(0), output1(0), output1(1));


  test_process : process
  begin
    wait for 10 * ckTime;
    for i in 0 to 1 loop
      for j in 0 to 3 loop
        input <= std_logic_vector(to_unsigned(j, 2));
        sel_s <= std_logic_vector(to_unsigned(i, 1));
        wait for ckTime;
        assert (output1 = output0) report "Mismatch:: " &
          " Input= " & integer'image(to_integer(unsigned(input))) &
          " sel= " & integer'image(j) &
          " Output= " & integer'image(to_integer(unsigned(output1))) &
          " Expectation= " & integer'image(to_integer(unsigned(output0)));
      end loop;

    end loop;

    wait;

  end process;

end Behavioral;
