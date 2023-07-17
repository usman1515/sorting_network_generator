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
    CLK_I : in std_logic;
    -- Synchronous Reset
    RST_I : in std_logic;

    -- M x W-Bit input treated as unsigned
    DATA_I         : in  SLVArray(0 to M - 1)(W - 1 downto 0);
    DATA_VALID_I   : in  std_logic;
    DATA_READY_O   : out std_logic;
    -- Bit indicating validity of received STREAM_I sequence. '1' indicates total ordering of STREAM_I
    -- sequence, '0' an order violation.
    IN_ORDER_O     : out std_logic;
    ALL_IN_ORDER_O : out std_logic
    );
end entity VALIDATOR;

architecture BEHAVIORAL of VALIDATOR is

  signal data                   : SLVArray(0 to M - 1)(W - 1 downto 0);
  signal cur_greater            : std_logic_vector(0 to M - 2);
  signal any_greater            : std_logic_vector(0 to M - 2);
  signal in_order, all_in_order : std_logic;

  signal busy         : std_logic;
  constant LIMIT      : integer := (W + SW - 1) / SW;
  signal counter      : integer range 0 to LIMIT;
  signal ready, valid : std_logic;
  signal is_new_data  : std_logic;
  signal start        : std_logic;

  signal input_slice : SLVArray(0 to M - 1)(SW-1 downto 0);

begin

  ALL_IN_ORDER_O <= all_in_order;
  IN_ORDER_O     <= in_order;
  DATA_READY_O   <= ready;
  valid          <= DATA_VALID_I;

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

  start <= is_new_data;

  READ_PROCESS : process (CLK_I) is
  begin
    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        data    <= (others => (others => '0'));
        busy    <= '0';
        counter <= LIMIT - 1;
      else
        if (busy = '0' and valid = '1') then
          busy <= '1';
          data <= DATA_I;
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
  SLICE_INPUT : process (counter, data) is
  begin
    for y in 0 to M -1 loop
      for x in SW-1 downto 0 loop
        input_slice(y)(x) <= data(y)(counter*SW + x);
      end loop;
    end loop;
  end process;

  SW_TO_SW_MUX : for i in 0 to M - 2 generate

    SERIALCOMPARE_1 : entity work.serialcompare
      generic map (
        SW => SW
        )
      port map (
        CLK_I        => CLK_I,
        OP_A_I       => input_slice(i),
        OP_B_I       => input_slice(i + 1),
        IS_EQUAL_O   => open,
        IS_LESS_O    => open,
        IS_GREATER_O => cur_greater(i),
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
        any_greater  <= (others => '0');
        all_in_order <= '1';
      elsif (busy = '0' and valid = '1') then
        any_greater <= (others => '0');
      else
        all_in_order <= in_order and all_in_order;

        for i in 0 to M - 2 loop
          any_greater(i) <= any_greater(i) or cur_greater(i);
        end loop;
      end if;
    end if;

  end process VALIDATE;

  ASSERT_ORDER : process (any_greater) is
  begin
    in_order <= '1';
    for i in 0 to M - 2 loop
      if any_greater(i) = '1' then
        in_order <= '0';
      end if;
    end loop;
  end process;


end architecture BEHAVIORAL;
