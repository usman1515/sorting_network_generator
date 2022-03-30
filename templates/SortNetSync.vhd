---------------------------------
-- Company:
-- Engineer:
--
-- Create Date:
-- -- Design Name:
-- Module Name: {top_name} - Behavioral
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
library work;
use work.CustomTypes.all;


entity {top_name} is
    generic(
      W : integer := {bit_width};
      Depth : integer := {net_depth};
      N : integer := {num_inputs}
    );
    port(
        CLK : in std_logic;
        E : in std_logic;
        R : in std_logic;
        input : in InOutArray(N-1 downto 0)(W-1 downto 0);
        output : out InOutArray(N-1 downto 0)(W-1 downto 0)
    );
end {top_name};

architecture Behavioral of {top_name} is

    type WireType is array (Depth downto 0) of std_logic_vector(N-1 downto 0);
    signal wire : WireType := (others => (others => '0'));

    signal S  : std_logic_vector(Depth downto 0) := (others=> '0');

    component CycleTimer is
      generic (
        w : integer);
      port (
        CLK : in  std_logic;
        R   : in  std_logic;
        E   : in  std_logic;
        S   : out std_logic);
    end component CycleTimer;

    {components}

begin

    CycleTimer_1 : CycleTimer
        generic map (
            w => w)
        port map (
            CLK => CLK,
            R => R,
            E => E,
            S => S(0)
            );

   StartDelay: process
   begin
   wait until rising_edge(CLK);
   S(S'high downto S'Low+1) <= S(S'high-1 downto S'low);
   end process;

  {instances}

end Behavioral;
