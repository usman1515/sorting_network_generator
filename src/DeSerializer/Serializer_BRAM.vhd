----------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Serializer_BRAM - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Serializer Component using an array to infer BRAM.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

library work;
  use work.CustomTypes.all;

entity SERIALIZER_BRAM is
  generic (
    -- Width of parallel input/ word.
    N : integer;
    -- Width of parallel input/ word.
    W : integer := 8;
    -- Subword length;
    SW : integer := 1
  );
  port (
    -- System Clock
    CLK                   : in    std_logic;
    -- Synchonous Reset
    RST                   : in    std_logic;
    -- Enable
    E                     : in    std_logic;
    -- Load signal
    LOAD                  : in    std_logic;
    -- w-bit parallel input
    PAR_INPUT             : in    SLVArray(0 to N - 1)(W - 1 downto 0);
    -- bit-serial output
    SER_OUTPUT            : out   std_logic_vector(0 to N - 1)
  );
end entity SERIALIZER_BRAM;

architecture BEHAVIORAL of SERIALIZER_BRAM is

  constant RADDR_WIDTH     : integer := integer(ceil(log2(real(W))));
  signal raddr             : integer range 0 to W - 1;
  signal slv_raddr         : std_logic_vector(RADDR_WIDTH - 1 downto 0);
    
  signal ser_output_i      : SLVArray(0 to N -1)(0 downto 0);
    
begin

  SET_SLV_RADDR : process(raddr) is
  begin
  
    slv_raddr <= std_logic_vector(to_unsigned(raddr, RADDR_WIDTH));
  
  end process SET_SLV_RADDR;
  
  SET_SER_OUTPUT: process(ser_output_i) is
  begin
  
    for i in 0 to N -1 loop
        SER_OUTPUT(i) <= ser_output_i(i)(0);
    end loop;
    
  end process SET_SER_OUTPUT;
  -- COUNTER----------------------------------------------------------------------
  -- Generic counter with reset and enable for address generation.
  --------------------------------------------------------------------------------
  COUNTER : process (CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1' or LOAD = '1') then
        raddr <= (W + SW - 1)/SW - 3;
      else
        if (E = '1') then
          if (raddr = 0) then
            raddr <= (W + SW - 1)/SW - 1;
          else
            raddr <= raddr - 1;
          end if;
        end if;
      end if;
    end if;

  end process COUNTER;

  LOADSHIFTREGISTERS : for i in 0 to N - 1 generate

    Load_Shift_Register_BRAM_1: entity work.Load_Shift_Register_BRAM
      generic map (
        W  => W,
        SW => 1)
      port map (
        CLK        => CLK,
        RST        => RST,
        E          => E,
        LOAD       => LOAD,
        RADDR      => slv_raddr,
        PAR_INPUT  => PAR_INPUT(i),
        SER_OUTPUT => ser_output_i(i));

  end generate LOADSHIFTREGISTERS;
end architecture BEHAVIORAL;
