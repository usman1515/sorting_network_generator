----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: BitCSwithShiftReg_Sim - Behavioral
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

entity BitCSwithShiftReg_Sim is
    generic(
        w : integer := 8
    );
end BitCSwithShiftReg_Sim;

architecture Behavioral of BitCSwithShiftReg_Sim is

    component BitCS is
        port (
            a     : in  std_logic;
            b     : in  std_logic;
            c     : out std_logic;
            d     : out std_logic;
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


    constant ckTime : time := 10 ns;

    signal clock : std_logic;
    signal a     : std_logic := '0';
    signal b     : std_logic := '0';
    signal c     : std_logic := '0';
    signal d     : std_logic := '0';
    signal S : std_logic := '0';

    signal LD : std_logic := '0';
    signal ST : std_logic := '0';

    signal Av : std_logic_vector(w-1 downto 0) := (others => '0');
    signal Bv : std_logic_vector(w-1 downto 0) := (others => '0');
    signal Cv : std_logic_vector(w-1 downto 0) := (others => '0');
    signal Dv : std_logic_vector(w-1 downto 0) := (others => '0');

    signal larger_value : std_logic_vector(w-1 downto 0) := (others => '0');
    signal smaller_value : std_logic_vector(w-1 downto 0) := (others => '0');
begin

    clock_process : process
    begin
        clock <= '0';
        wait for ckTime/2;
        clock <= '1';
        wait for ckTime/2;
    end process;

    uut_0 : BitCS
        port map( a, b, c, d, S);

    LoadShiftRegister_1 : LoadShiftRegister
        generic map (
            w => w)
        port map (
            CLK        => clock,
            input      => Av,
            LD         => LD,
            ser_output => a);
    LoadShiftRegister_2 : LoadShiftRegister
        generic map (
            w => w)
        port map (
            CLK        => clock,
            input      => Bv,
            LD         => LD,
            ser_output => b);

    StoreShiftRegister_1 : StoreShiftRegister
        generic map (
            w => w)
        port map (
            CLK       => clock,
            ser_input => c,
            ST        => ST,
            output    => Cv);
    StoreShiftRegister_2 : StoreShiftRegister
        generic map (
            w => w)
        port map (
            CLK       => clock,
            ser_input => d,
            ST        => ST,
            output    => Dv);

    test_process : process

    begin

        larger_value    <= "10110110";
        smaller_value    <= "10100111";
        wait for ckTime/2;

        Av <= larger_value;
        Bv <= smaller_value;

        for i in 0 to w-1 loop
            wait for ckTime;
            LD <= '1' when i = 0 else '0';
            S <= '1' when i = 1 else '0';
            ST <= '1' when i = 2 else '0';
        end loop;

        Av    <= smaller_value;
        Bv    <= larger_value;

        for i in 0 to w-1 loop
            wait for ckTime;
            LD <= '1' when i = 0 else '0';
            S <= '1' when i = 1 else '0';
            ST <= '1' when i = 2 else '0';
            if i = 3 then
                assert ((larger_value = Cv) and (smaller_value = Dv)) report "Mismatch:: " &
              " Av= " & integer'image(to_integer(unsigned(larger_value))) &
              " Bv= " & integer'image(to_integer(unsigned(smaller_value))) &
              " Cv= " & integer'image(to_integer(unsigned(Cv))) &
              " Dv= " & integer'image(to_integer(unsigned(Dv))) &
              " Expectation Av=Cv and Bv=Dv";
            end if;
        end loop;


        for i in 0 to w-1 loop
            wait for ckTime;
            LD <= '1' when i = 0 else '0';
            S <= '1' when i = 1 else '0';
            ST <= '1' when i = 2 else '0';
            if i = 3 then
                assert ((larger_value = Cv) and (smaller_value = Dv)) report "Mismatch:: " &
              " Av= " & integer'image(to_integer(unsigned(smaller_value))) &
              " Bv= " & integer'image(to_integer(unsigned(larger_value))) &
              " Cv= " & integer'image(to_integer(unsigned(Cv))) &
              " Dv= " & integer'image(to_integer(unsigned(Dv))) &
              " Expectation Av=Dv and Bv=Cv";
            end if;
        end loop;

        wait;

    end process;

end Behavioral;
