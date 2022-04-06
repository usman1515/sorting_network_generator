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
    constant N : integer := 4;

    component ValidatorTree is
      generic (
        W : integer;
        N : integer);
      port (
        CLK       : in  std_logic;
        E         : in  std_logic;
        R         : in  std_logic;
        input_max : in  SLVArray(N/W-1 downto 0)(W-1 downto 0);
        input_min : in  SLVArray(N/W-1 downto 0)(W-1 downto 0);
        valid_in  : in  std_logic_vector(N/W-1 downto 0);
        valid_out : out std_logic);
    end component ValidatorTree;

    component Validator is
      generic (
        W : integer);
      port (
        CLK   : in  std_logic;
        E     : in  std_logic;
        R     : in  std_logic;
        input : in  std_logic_vector(W-1 downto 0);
        maxV  : out std_logic_vector(W-1 downto 0);
        minV  : out std_logic_vector(W-1 downto 0);
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

    component SortNetSimple is
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
    end component SortNetSimple;

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

    constant seed : std_logic_vector(W-1 downto 0) := "10110001";
    constant P : std_logic_vector(W-1 downto 0) := "01101010";

    signal R : std_logic := '0';
    signal E : std_logic_vector(3 downto 0) := (others => '0');
    -- Output of LFSR
    signal LFSR_out : std_logic_vector(W-1 downto 0)            := (others => '0');
    -- Output of Round-Robin DMUX
    signal DMUX_out : SLVArray(N-1 downto 0)(W-1 downto 0)    := (others => (others => '0'));
    -- Output of Sorting Network
    signal SN_out   : SLVArray(N-1 downto 0)(W-1 downto 0)    := (others => (others => '0'));
    -- Output of Round-Robin Multiplexer
    signal MUX_out  : std_logic_vector(W-1 downto 0)            := (others => '0');
    -- Outputs of Validators
    signal ValMax_out : SLVArray(0 downto 0)(W-1 downto 0):= (others => (others => '0'));
    signal ValMin_out : SLVArray(0 downto 0)(W-1 downto 0):= (others => (others => '0'));
    signal ValLocal_out : std_logic_vector(0 downto 0) := (others => '0');
    -- Output of Validator Tree.
    signal ValT_out : std_logic := '0';

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

        E(0) <= '0';
        wait for ckTime/2;
        R <= '1';
        wait for ckTime;
        R <= '0';
        E(0) <= '1';
        wait for (W)*ckTime;

        wait;

    end process;

    LFSR_1: entity work.LFSR
      generic map (
        W => W,
        P => P)
      port map (
        CLK    => CLK,
        E      => E(0),
        R      => R,
        seed   => seed,
        output => LFSR_out);

    RRDMUX_NxW_1: entity work.RRDMUX_NxW
      generic map (
        W => W,
        N => N)
      port map (
        CLK    => CLK,
        E      => E(0),
        R      => R,
        input  => LFSR_out,
        output => DMUX_out);

    EnableDelay_1: entity work.ShiftRegister
      generic map (
        W => N-1) --min(N,W) -1 )
      port map (
        CLK   => CLK,
        E     => not R,
        R     => R,
        s_in  => E(0),
        s_out => E(1));

    SortNetSimple_1: SortNetSimple
        generic map (
            W => W)
        port map (
            CLK    => CLK,
            E      => E(1),
            R      => R,
            input  => DMUX_out,
            output => SN_out);

    EnableDelay_2: entity work.ShiftRegister
      generic map (
        W => W+Depth+1)
      port map (
        CLK   => CLK,
        E     => not R,
        R     => R,
        s_in  => E(1),
        s_out => E(2));

    RRMUX_NxW_1: entity work.RRMUX_NxW
      generic map (
        W => W,
        N => N)
      port map (
        CLK    => CLK,
        E      => E(2),
        R      => R,
        input  => SN_out,
        output => MUX_out);

    EnableDelay_3: entity work.ShiftRegister
      generic map (
        W => N) --min(N,W))
      port map (
        CLK   => CLK,
        E     => not R,
        R     => R,
        s_in  => E(2),
        s_out => E(3));

    Validator_1: entity work.Validator
      generic map (
        W => W)
      port map (
        CLK   => CLK,
        E     => E(3),
        R     => R,
        input => MUX_out,
        maxV  => ValMax_out(0),
        minV  => ValMin_out(0),
        valid => ValLocal_out(0));

    ValidatorTree_1: entity work.ValidatorTree
      generic map (
        W => W,
        N => N)
      port map (
        CLK       => CLK,
        E         => not R,
        R         => R,
        input_max => ValMax_out,
        input_min => ValMin_out,
        valid_in  => ValLocal_out,
        valid_out => ValT_out);

end Behavioral;
