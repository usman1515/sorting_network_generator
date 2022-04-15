------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 03/10/2022 04:55:22 PM
-- Design Name:
-- Module Name: SortNetSimple - Behavioral
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


entity SortNetSimple is
  generic(
    w : integer := 8
    );
  port(
    CLK    : in  std_logic;
    E      : in  std_logic;
    R      : in  std_logic;
    input  : in  SLVArray(3 downto 0)(w-1 downto 0);
    output : out SLVArray(3 downto 0)(w-1 downto 0)
    );
end SortNetSimple;

architecture Behavioral of SortNetSimple is

  component BitCS_Sync is
    port (
      CLK : in  std_logic;
      a   : in  std_logic;
      b   : in  std_logic;
      c   : out std_logic;
      d   : out std_logic;
      S   : in  std_logic);
  end component BitCS_Sync;

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
  component CycleTimer is
    generic (
      w : integer);
    port (
      CLK : in  std_logic;
      R   : in  std_logic;
      E   : in  std_logic;
      S   : out std_logic);
  end component CycleTimer;

  type GRID2D is array (3 downto 0) of std_logic_vector(3 downto 0);

  signal wire : GRID2D := (others => (others => '0'));


  signal S  : std_logic_vector(3 downto 0) := (others=> '0');

begin

  InputShift :
  for i in 0 to 3 generate
    LSR : LoadShiftRegister
      generic map (
        w => w)
      port map (
        CLK        => CLK,
        E          => E,
        LD         => S(S'low),
        input      => input(i),
        ser_output => wire(i)(0));
  end generate InputShift;

  OutputShift :
  for i in 0 to 3 generate
    SSR : StoreShiftRegister
      generic map (
        w => w)
      port map (
        CLK       => CLK,
        E         => E,
        ST        => S(S'high),
        output    => output(i),
        ser_input => wire(i)(3));
  end generate OutputShift;

  BitCS_Sync_0 : BitCS_Sync
    port map(
      CLK => CLK,
      a => wire(1)(0),
      b => wire(0)(0),
      c => wire(1)(1),
      d => wire(0)(1),
      S => S(0)
      );
  BitCS_Sync_1 : BitCS_Sync
    port map(
      CLK => CLK,
      a => wire(3)(0),
      b => wire(2)(0),
      c => wire(3)(1),
      d => wire(2)(1),
      S => S(0)
      );
  BitCS_Sync_2 : BitCS_Sync
    port map(
      CLK => CLK,
      a => wire(2)(1),
      b => wire(0)(1),
      c => wire(2)(2),
      d => wire(0)(2),
      S => S(1)
      );
  BitCS_Sync_3 : BitCS_Sync
    port map(
      CLK => CLK,
      a => wire(3)(1),
      b => wire(1)(1),
      c => wire(3)(2),
      d => wire(1)(2),
      S => S(1)
      );
  BitCS_Sync_4 : BitCS_Sync
    port map(
      CLK => CLK,
      a => wire(2)(2),
      b => wire(1)(2),
      c => wire(2)(3),
      d => wire(1)(3),
      S => S(2)
      );

  process
  begin
    wait until rising_edge(CLK);
    wire(3)(3 downto 2 + 1) <= wire(3)(3 - 1 downto 2);
    wire(0)(3 downto 2 + 1) <= wire(0)(3 - 1 downto 2);
  end process;

  CycleTimer_1 : CycleTimer
    generic map (
      w => w)
    port map (
      CLK => CLK,
      R   => R,
      E   => E,
      S   => S(0));
      
   process
   begin
   wait until rising_edge(CLK);
   S(S'high downto S'Low+1) <= S(S'high-1 downto S'low);
   end process;


end Behavioral;
