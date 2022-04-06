library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

entity Validator is
generic(
  W : integer := 8 -- Bit-Width of input values.
);
port(
    CLK : in std_logic;  -- Clock signal
    E : in std_logic;  -- Enable signal
    R : in std_logic;  -- Synchronous Reset
    input : in std_logic_vector(W-1 downto 0); -- W-Bit input treated as unsigned
    maxV : out std_logic_vector(W-1 downto 0); -- W-Bit maximum inputs received
                                               -- since reset
    minV : out std_logic_vector(W-1 downto 0); -- W-Bit minium inputs recieved
                                               -- since reset
    valid : out std_logic -- Bit indicating validity of received input
                          -- sequence. '1' indicates total ordering of input sequence,
                          -- '0' order violation.
    );
end Validator;

architecture Behavioral of Validator is
  signal rmaxV : std_logic_vector(W-1 downto 0) := (others => '0');
  signal rminV : std_logic_vector(W-1 downto 0) := (others => '0');
begin

  maxV <= rmaxV;
  minV <= rminV;

  process
  begin
    wait until rising_edge(CLK);
    if R = '1' then
      rmaxV <= (others => '0');
      rminV <= (others => '1');
      valid <= '1';
    else
      if E = '1' then
        if unsigned(input) > unsigned(rmaxV) then
          rmaxV <= input;
        end if;
        if unsigned(input) < unsigned(rminV) then
          rminV <= input;
        end if;
        if unsigned(input) < unsigned(rmaxV) then
          valid <= '0';
        end if;
      end if;
    end if;
  end process;

end Behavioral;
