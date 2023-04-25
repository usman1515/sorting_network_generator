----------------------------------------------------------------------------------
-- Author: Stephan Proß
--
-- Create Date: 03/08/2022 02:46:11 PM
-- Design Name:
-- Module Name: Signal_Distributor - Behavioral
-- Project Name: BitSerialCompareSwap
-- Tool Versions: Vivado 2021.2
-- Description: Takes an input signal and replicates it in a tree-like fashion
-- using registers. Infers a delay dependent on the number of tree stages.
--
----------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use IEEE.math_real.all;

entity SIGNAL_DISTRIBUTOR is
  generic (
    -- Size of subword to be compared at a time.
    NUM_SIGNALS : integer := 8;
    MAX_FANOUT  : integer := 2
  );
  port (
    -- System Clock.
    CLK_I      : in    std_logic;
    -- Synchronous reset
    RST_I      : in    std_logic;
    -- Enable Signal
    ENABLE_I   : in    std_logic;
    -- Signal input to replicate
    SOURCE_I   : in    std_logic;
    -- Replicated output signals.
    REPLIC_O   : out   std_logic_vector(0 to NUM_SIGNALS - 1);
    -- Feedback signal to allow signal source handling of imposed delay
    FEEDBACK_O : out   std_logic
  );
end entity SIGNAL_DISTRIBUTOR;

architecture BEHAVIORAL of SIGNAL_DISTRIBUTOR is

  constant N  : integer := NUM_SIGNALS;
  constant B  : integer := MAX_FANOUT;

  -- Number of stages in the tree.
  constant S  : integer := integer(CEIL(LOG(real(N), real(B))));

  -- Represents the tree as a 1D array.
  signal tree : std_logic_vector(0 to (B ** (S)));

begin


  -- DISTRIBUTE -------------------------------------------------------------------
  -- Performs the tree like signal distribution by interpreting A as tree.
  --------------------------------------------------------------------------------
  DISTRIBUTE : process (CLK_I) is
    variable target,source : integer;
  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        tree(0 to tree'high) <= (others => '0');
      else
        if (ENABLE_I = '1') then

          for i in 0 to S - 1 loop
            
            for j in 0 to B ** i loop
              target := B**i + j;
              source := (B**i - 1 + j) / B;
              if (source = 0) then
                tree(target) <= SOURCE_I;
              else
                tree(target) <= tree(source);
               end if;

            end loop;

          end loop;

        end if;
      end if;
    end if;

  end process DISTRIBUTE;

  -- REPLIC_OUT -------------------------------------------------------------------
  -- Sets replic_O to the last stage indices fo tree asyncronously.
  --------------------------------------------------------------------------------
  REPLIC_OUT : process (tree, RST_I) is

  begin

    if (RST_I = '1') then
      REPLIC_O   <= (others => '0');
      FEEDBACK_O <= '0';
    else
      -- FEEDBACK value is taken from the first replicated output.
      FEEDBACK_O <= tree((B ** (S-1)));

      for i in 0 to NUM_SIGNALS - 1 loop

        REPLIC_O(i) <= tree((B ** (S-1) + i ));

      end loop;

    end if;

  end process REPLIC_OUT;

end architecture BEHAVIORAL;
