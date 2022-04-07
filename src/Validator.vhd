library ieee;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

library work;
  use work.CustomTypes.all;

entity validator is
  generic (
    w : integer := 8; -- Bit-Width of input values.
    n : integer := 4  -- Number of w-Bit inputs.
  );
  port (
    clk   : in    std_logic;                                -- Clock signal
    r     : in    std_logic;                                -- Synchronous Reset
    e     : in    std_logic;                                -- Enable signal
    input : in    SLVArray(n - 1 downto 0)(w - 1 downto 0); -- N x W-Bit input treated as unsigned
    valid : out   std_logic                                 -- Bit indicating validity of received input
    -- sequence. '1' indicates total ordering of input sequence,
    -- '0' an order violation.
  );
end entity validator;

architecture behavioral of validator is

  signal valid_i : std_logic;

begin

  validate : process is
  begin

    wait until rising_edge(clk);

    if (r = '1') then
      valid_i <= '1'; -- Input is assumed to be valid at the beginning.
    else
      if (e = '1') then

        for i in 0 to n - 2 loop

          -- If any input value is not in order, set valid_i to 0
          if (unsigned(input(i)) > unsigned(input(i + 1))) then
            valid_i <= '0';
          end if;

        end loop;

      end if;
    end if;

  end process validate;

  outputvalid : process is
  begin

    wait until rising_edge(clk);

    if (r='0' and e='1') then
      -- Only output valid_i if enabled and not reset.
      valid <= valid_i;
    else
      valid <= '0';
    end if;

  end process outputvalid;

end architecture behavioral;
