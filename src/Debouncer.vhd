library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

entity Debouncer is
  generic(
    timeout_cycles : integer := 50 -- Number of cycles until a change in output
                                   -- signal is allowed.
);
port(
  CLK       : in std_logic;  -- System Clock signal
  R         : in std_logic; -- Synchronous Reset
  input     : in std_logic; -- Bouncing input
  output    : out std_logic -- Debounced ouput signal
  );
end Debouncer;

architecture Behavioral of Debouncer is
  signal count : integer range 0 to timeout_cycles-1;
  signal output_i : std_logic;
begin

  output <= output_i;

  Debounce: process(CLK)
  begin
    if rising_edge(CLK) then
      if R = '1' then
        count <= 0;
        output_i <= input;
      else
        if count < timeout_cycles-1 then
          count <= count +1;
        elsif input /= output_i then
          count <= 0;
          output_i <= input;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
