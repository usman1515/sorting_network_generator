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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BitCS is
    Port (
        a : in std_logic;
        b : in std_logic;
        c : out std_logic;
        d : out std_logic;
        CLK : in std_logic;
        R : in std_logic);
end BitCS;

architecture Behavioral of BitCS is
    TYPE STATE_TYPE IS (EQUAL, INIT, LARGER, SMALLER);
    SIGNAL state   : STATE_TYPE := INIT;

begin

    StateMachine: process(CLK, R)
    begin
        if(CLK'EVENT AND CLK= '1') THEN
            if R= '1' THEN
                state <= INIT;
            else
                case state is
                    when INIT=>
                        if a='1' AND b = '0' then
                            state <= LARGER;
                        elsif a='0' AND b ='1' then
                            state <= SMALLER;
                        else
                            state <= EQUAL;
                        end if;
                    when EQUAL=>
                        if a='1' AND b = '0' then
                            state <= LARGER;
                        elsif a='0' AND b ='1' then
                            state <= SMALLER;
                        else
                            state <= EQUAL;
                        end if;
                    when LARGER=>
                        state <= LARGER;
                    when SMALLER=>
                        state <= SMALLER;
                end case;
            end if;
        end if;
    end process;


    MUX: process
    begin
        wait until rising_edge(CLK);
        if state = SMALLER then
            c <= b;
            d <= a;
        else
            c <= a;
            d <= b;
        end if;
    end process;


end Behavioral;
