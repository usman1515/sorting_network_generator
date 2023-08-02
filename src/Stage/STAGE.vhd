-------------------------------------------------------------------------------
-- Title      : Stage
-- Project    :
-------------------------------------------------------------------------------
-- File       : STAGE.vhd
-- Author     : Stephan Proß <Stephan.Pross@web.de>
-- Company    :
-- Created    : 2023-06-27
-- Last update: 2023-08-02
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Compare Swap stage of arbitrary sorting network.
-------------------------------------------------------------------------------
-- Copyright (c) 2023
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-06-27  1.0      li436   Created
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.CustomTypes.all;

entity Stage is

  generic (
    -- Number of inputs or length of the stage.
    N          : integer     := 8;
    -- Data width
    SW         : natural     := 1;
    -- CS configuration. Every index out of order indicates CS.
    PERM       : Permutation := (0, 1, 5, 4, 3, 2, 7, 6);
    -- Number of START signals going in and out of the stage.
    NUM_START  : natural     := 2;
    -- Number of ENABLE signals going in and out of the stage.
    NUM_ENABLE : natural     := 2
    );
  port (
    -- System clock
    CLK_I    : in  std_logic;
    -- Synchronous reset.
    RST_I    : in  std_logic;
    -- Enable Signal, currently unused.
    ENABLE_I : in  std_logic_vector(0 to NUM_ENABLE-1);
    -- Start signal marking the beginning of a new word.
    START_I  : in  std_logic_vector(0 to NUM_START-1);
    -- Serial input of the N input words.
    STREAM_I : in  SLVArray(0 to N - 1)(SW - 1 downto 0);
    -- Serial output of the M output words.
    STREAM_O : out SLVArray(0 to N - 1)(SW - 1 downto 0)
    );

end entity Stage;

architecture BEHAVIORAL of Stage is
  signal output : SLVArray(0 to N -1)(SW-1 downto 0);
begin  -- architecture BEHAVIORAL

  CS_GENERATE_FOR : for i in 0 to N -1 generate
    CS_GENERATE_IF : if PERM(i) > i generate

      SWCS_1 : entity work.SWCS
        generic map (
          SW => SW)
        port map (
          CLK_I   => CLK_I,
          A_I     => STREAM_I(PERM(i)),
          B_I     => STREAM_I(i),
          A_O     => output(PERM(i)),
          B_O     => output(i),
          START_I => START_I(i / (N/ NUM_START))
          );

    end generate CS_GENERATE_IF;

    FF_GENERATE_IF : if PERM(i) = i generate
      WordRegister_1 : entity work.WordRegister
        generic map (
          W => SW)
        port map (
          CLK_I    => CLK_I,
          RST_I    => '0',
          ENABLE_I => '1',
          D_I      => STREAM_I(i),
          D_O      => output(i)
          );
    end generate FF_GENERATE_IF;
  end generate CS_GENERATE_FOR;
  -- For some reason, simulation with vivado will only recognize swapped values
  -- if the intermediate signal 'output' is used.
  STREAM_O <= output;
end architecture BEHAVIORAL;
