library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity Validator is
generic(
W : integer := 8; -- Bit-Width of input values.
N : integer := 4   -- Number of w-Bit inputs.
);
port(
  CLK : in std_logic;  -- Clock signal
  R : in std_logic;  -- Synchronous Reset
  E : in std_logic;  -- Enable signal
  input : in SLVArray(N-1 downto 0)(W-1 downto 0); -- N x W-Bit input treated as unsigned
  valid : out std_logic -- Bit indicating validity of received input
                        -- sequence. '1' indicates total ordering of input sequence,
                        -- '0' an order violation.
  );
end Validator;

architecture Behavioral of Validator is
signal valid_i : std_logic := '0';
begin

Validate: process
begin
  wait until rising_edge(CLK);
  if R = '1' then
    valid_i <= '1'; -- Input is assumed to be valid at the beginning.
  else
    if E = '1' then
      for i in 0 to N-2 loop
        -- If any input value is not in order, set valid_i to 0
        if unsigned(input(i)) > unsigned(input(i+1)) then
          valid_i <= '0';
        end if;
      end loop;
    end if;
  end if;
end process;

OutputValid: process
begin
  wait until rising_edge(CLK);
  if R='0' and E='1' then
    -- Only output valid_i if enabled and not reset.
    valid <= valid_i;
  else
    valid <= '0';
  end if;
end process;

end Behavioral;
