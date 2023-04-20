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
    CLK_I    : in  std_logic;
    -- Synchronous reset
    RST_I    : in  std_logic;
    -- Enable Signal
    ENABLE_I : in  std_logic;
    -- Signal input to replicate
    SOURCE_I : in  std_logic;
    -- Replicated output signals.
    REPLIC_O : out std_logic_vector(0 to NUM_SIGNALS - 1);
    -- Feedback signal to allow signal source handling of imposed delay
    FEEDBACK_O : out std_logic
    );
end entity SIGNAL_DISTRIBUTOR;

architecture BEHAVIORAL of SIGNAL_DISTRIBUTOR is

  constant X : integer := NUM_SIGNALS;
  constant Y : integer := MAX_FANOUT;

  -- Number of stages in the tree.
  constant S : integer := integer(CEIL(LOG(real(X), real(Y))));

  -- Represents the tree as a 1D array.
  signal tree : std_logic_vector(0 to (Y **(S+1) - 1)/(Y - 1) - 1);

begin



  -- DISTRIBUTE -------------------------------------------------------------------
  -- Performs the tree like signal distribution by interpreting A as tree.
  --------------------------------------------------------------------------------
  DISTRIBUTE : process (CLK_I) is

  begin

    if (rising_edge(CLK_I)) then
      if (RST_I = '1') then
        tree <= (others => '0');
      else
        if (ENABLE_I = '1') then
          tree(0) <= SOURCE_I;
          for i in 1 to S loop

            for j in 0 to Y ** i - 1 loop

              tree((Y**i - 1) / (Y - 1) + j) <= tree((Y ** i - 1) / (Y - 1) - Y ** (i - 1) + j / Y);

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
      REPLIC_O <= (others => '0');
      FEEDBACK_O <= '0';
    else

      -- FEEDBACK value is taken from the first replicated output.
      FEEDBACK_O <= tree((Y ** (S-1) - 1)/(Y - 1) + 1);

      for i in 0 to NUM_SIGNALS - 1 loop

        REPLIC_O(i) <= tree((Y ** (S-1) - 1)/(Y - 1) + 1 + i);

      end loop;

    end if;

  end process REPLIC_OUT;

end architecture BEHAVIORAL;
