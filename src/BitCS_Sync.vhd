----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name: 
-- Module Name: BitCS_Sync - Behavioral
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
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity BitCS_Sync is
    port (
        CLK : in std_logic;
        a : in  std_logic;
        b : in  std_logic;
        c : out std_logic;
        d : out std_logic;
        S : in  std_logic
    );
end BitCS_Sync;


architecture Behavioral of BitCS_Sync is

    component MUX is
        port (
            a   : in  std_logic;
            b   : in  std_logic;
            sel : in  std_logic;
            c   : out std_logic;
            d   : out std_logic);
    end component MUX;

    signal state : std_logic_vector(1 downto 0) := "00";
    signal nstate : std_logic_vector(1 downto 0) := "00";
    signal c_s : std_logic := '0';
    signal d_s : std_logic := '0';

begin

    process(a, b, S, state)
    begin
        case state is
            when "00" =>
                if a = '1' and b = '0' then
                    nstate <= "01";
                elsif a = '0' and b = '1' then
                    nstate <= "10";
                else
                    nstate <= "00";
                end if;
            when "01" =>
                if S = '1' then
                    if a = '1' and b = '0' then
                        nstate <= "01";
                    elsif a = '0' and b = '1' then
                        nstate <= "10";
                    else
                        nstate <= "00";
                    end if;
                else
                    nstate <= "01";
                end if;
            when "10" =>
                if S = '1' then
                    if a = '1' and b = '0' then
                        nstate <= "01";
                    elsif a = '0' and b = '1' then
                        nstate <= "10";
                    else
                        nstate <= "00";
                    end if;
                else
                    nstate <= "10";
                end if;
            when others =>
                nstate <= "00";
        end case;
    end process;

    process
    begin
        wait until rising_edge(CLK);
        state <= nstate;
    end process;

    MUX_1: MUX
        port map (
            a   => a,
            b   => b,
            sel => nstate(1),
            c   => c_s,
            d   => d_s);

    process
    begin
        wait until rising_edge(CLK);
        c <= c_s;
        d <= d_s;

    end process;

end Behavioral;
