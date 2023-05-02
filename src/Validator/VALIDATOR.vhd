----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Validator - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Validates order of input sequence. Treats values at input as unsigned.
--
----------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity VALIDATOR is
  generic (
    -- Number of w-Bit inputs.
    M  : integer := 4;
    W  : integer := 8;
    SW : integer := 1
    );
  port (
    -- Clock signal
    CLK_I    : in std_logic;
    -- Synchronous Reset
    RST_I    : in std_logic;
    -- Enable signal
    ENABLE_I : in std_logic;

    -- M x W-Bit input treated as unsigned
    DATA_I       : in  SLVArray(0 to M - 1)(W - 1 downto 0);
    DATA_VALID_I : in  std_logic;
    DATA_READY_O : out std_logic;
    -- Bit indicating validity of received STREAM_I sequence. '1' indicates total ordering of STREAM_I
    -- sequence, '0' an order violation.
    IN_ORDER_O   : out std_logic
    );
end entity VALIDATOR;

architecture BEHAVIORAL of VALIDATOR is

  signal data        : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal cur_lesser : std_logic_vector(0 to M - 2);
  signal any_lesser : std_logic;

  signal busy         : std_logic;
  constant LIMIT      : integer := (W + SW - 1) / SW;
  signal counter      : integer range 0 to LIMIT;
  signal ready, valid : std_logic;
  signal is_new_data  : std_logic;
  signal start        : std_logic;

begin

  DATA_READY_O <= ready;
  valid        <= DATA_VALID_I;

  REGISTER_DATA_EXCHANGE : process (CLK_I) is
  begin
    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        is_new_data <= '0';
      else
        is_new_data <= (ready and valid);
      end if;
    end if;

  end process REGISTER_DATA_EXCHANGE;

  -- start <= '1' when (ready and valid) and not is_new_data else
  --          '0';

  READ_PROCESS : process (CLK_I) is
  begin
    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        data    <= (others => (others => '0'));
        busy    <= '0';
        counter <= LIMIT - 1;
        start <= '0';
      else
        start <= '0';
        if (busy = '0' and valid = '1') then
          busy <= '1';
          data <= DATA_I;
          start <= '1';
        else
          if (busy = '1') then
            if (counter = 0) then
              counter <= LIMIT - 1;
              busy    <= '0';
            else
              counter <= counter - 1;
            end if;
          end if;
        end if;
      end if;
    end if;

  end process READ_PROCESS;

  ready <= not busy;

  SW_TO_SW_MUX : for i in 0 to M - 2 generate

    SERIALCOMPARE_1 : entity work.serialcompare
      generic map (
        SW => SW
        )
      port map (
        CLK_I        => CLK_I,
        OP_A_I       => data(i)(counter*SW downto (counter + 1)*SW - 1),
        OP_B_I       => data(i + 1)(counter*SW downto (counter + 1)*SW - 1),
        IS_EQUAL_O   => open,
        IS_LESS_O    => cur_lesser(i),
        IS_GREATER_O => open,
        START_I      => start
        );

  end generate SW_TO_SW_MUX;

  -- VALIDATE--------------------------------------------------------------------
  -- On reset, inputs are assumed to be IN_ORDER_O. Afterwards, all inputs are
  -- pairwise compared in parallel in an interleaved fashion to deduce correct ordering.
  -- Once an order violation is detected, IN_ORDER_O will only be set on reset.
  -------------------------------------------------------------------------------
  VALIDATE : process (CLK_I) is
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        any_lesser <= '0';
      else
        if (ENABLE_I = '1') then

          for i in 0 to M - 2 loop

            any_lesser <= any_lesser or cur_lesser(i);

          end loop;

        end if;
      end if;
    end if;

  end process VALIDATE;

  IN_ORDER_O <= '1' when not any_lesser else '0';

end architecture BEHAVIORAL;
