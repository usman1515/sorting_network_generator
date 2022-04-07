-------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: Sim_BitCS_SortNetSimple - Behavioral
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

entity Sim_Sorter is
end Sim_Sorter;

architecture Behavioral of Sim_Sorter is
    constant W : integer := 8;
    constant Depth : integer := 3;
    constant N : integer := 16;

    component Validator is
        generic (
            W : integer;
            N : integer);
        port (
            CLK   : in  std_logic;
            R     : in  std_logic;
            E     : in  std_logic;
            input : in  SLVArray(N-1 downto 0)(W-1 downto 0);
            valid : out std_logic);
    end component Validator;

    component RRMUX_NxW is
      generic (
        W : integer;
        N : integer);
      port (
        CLK    : in  std_logic;
        E      : in  std_logic;
        R      : in  std_logic;
        input  : in  SLVArray(N-1 downto 0)(W-1 downto 0);
        output : out std_logic_vector(W-1 downto 0));
    end component RRMUX_NxW;

    component EvenOdd16 is
        generic (
            W : integer
        );
        port (
            CLK    : in  std_logic;
            E      : in  std_logic;
            R      : in  std_logic;
            input  : in  SLVArray(N-1 downto 0)(W-1 downto 0);
            output : out SLVArray(N-1 downto 0)(W-1 downto 0)
        );
    end component EvenOdd16;

    component ShiftRegister is
      generic (
        W : integer);
      port (
        CLK   : in  std_logic;
        E     : in  std_logic;
        R     : in  std_logic;
        s_in  : in  std_logic;
        s_out : out std_logic);
    end component ShiftRegister;

    component RRDMUX_NxW is
      generic (
        W : integer;
        N : integer);
      port (
        CLK    : in  std_logic;
        E      : in  std_logic;
        R      : in  std_logic;
        input  : in  std_logic_vector(W-1 downto 0);
        output : out SLVArray(N-1 downto 0)(W-1 downto 0));
    end component RRDMUX_NxW;

    component LFSR is
      generic (
        W : integer;
        P : std_logic_vector);
      port (
        CLK    : in  std_logic;
        E      : in  std_logic;
        R      : in  std_logic;
        seed   : in  std_logic_vector(W-1 downto 0);
        output : out std_logic_vector(W-1 downto 0));
    end component LFSR;

    constant ckTime : time := 10 ns;
    signal CLK : std_logic;

    constant seed_i : std_logic_vector(W-1 downto 0) := "10110001";
    constant P_i : std_logic_vector(W-1 downto 0) := "01101010";

    signal R : std_logic := '0';
    signal E : std_logic := '0';

    signal E_delayed_i : std_logic_vector(2 downto 0) := (others => '0');
    -- Output of LFSRs
    signal rand_data_i : SLVArray(N/W-1 downto 0)(W-1 downto 0)      := (others => (others => '0'));
    -- Output of Round-Robin DMUXs
    signal unsorted_data_i : SLVArray(N-1 downto 0)(W-1 downto 0)    := (others => (others => '0'));
    -- Output of Sorting Network
    signal sorted_data_i   : SLVArray(N-1 downto 0)(W-1 downto 0)    := (others => (others => '0'));
    
    signal valid : std_logic := '0';


begin

    CLK_process : process
    begin
        CLK <= '0';
        wait for ckTime/2;
        CLK <= '1';
        wait for ckTime/2;
    end process;

    test_process : process

    begin

        E <= '0';
        wait for ckTime/2;
        R <= '1';
        wait for ckTime;
        R <= '0';
        E <= '1';
        wait for (W)*ckTime;

        wait;

    end process;

   INPUT :for i in 0 to N/W -1 generate
    LFSR_1: LFSR
      generic map (
        W => W,
        P => P_i)
      port map (
        CLK    => CLK,
        E      => E,
        R      => R,
        seed   => seed_i,
        output => rand_data_i(i));
    RRDMUX_NxW_1: RRDMUX_NxW
      generic map (
        W => W,
        N => W)
      port map (
        CLK    => CLK,
        E      => E,
        R      => R,
        input  => rand_data_i(i),
        output => unsorted_data_i((i+1)*W -1 downto i*W));
  end generate;

    EnableDelay_1: entity work.ShiftRegister
      generic map (
        W => W-1) --min(N,W) -1 )
      port map (
        CLK   => CLK,
        E     => not R,
        R     => R,
        s_in  => E,
        s_out => E_delayed_i(0));

    SortNet: EvenOdd16
        generic map (
            W => W)
        port map (
            CLK    => CLK,
            E      => E_delayed_i(0),
            R      => R,
            input  => unsorted_data_i,
            output => sorted_data_i);

    EnableDelay_2: entity work.ShiftRegister
      generic map (
        W => W+Depth+1)
      port map (
        CLK   => CLK,
        E     => not R,
        R     => R,
        s_in  => E_delayed_i(0),
        s_out => E_delayed_i(1));

    Validator_1: entity work.Validator
      generic map (
        W => W,
        N => N)
      port map (
        CLK   => CLK,
        E     => E_delayed_i(1),
        R     => R,
        input => sorted_data_i,
        valid => valid);

end Behavioral;
