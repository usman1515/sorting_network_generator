-------------------------------------------------------------------------------
-- Title      : Stage
-- Project    :
-------------------------------------------------------------------------------
-- File       : STAGE.vhd
-- Author     : Stephan Proß <Stephan.Pross@web.de>
-- Company    :
-- Created    : 2023-06-27
-- Last update: 2023-08-29
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
    N               : integer     := 8;
    -- Data width
    SW              : integer     := 1;
    -- CS configuration. Every index out of order indicates CS.
    PERM            : Permutation := (0, 1, 5, 4, 3, 2, 6, 7);
    -- Number of Delay-Registers inferred by permutation.
    NUM_DELAY       : integer     := 4;
    -- Number of START signals going in and out of the stage.
    NUM_START       : integer     := 2;
    -- Number of ENABLE signals going in and out of the stage.
    NUM_ENABLE      : integer     := 2;
    -- Maximum number of DSP for replacement of Registers
    NUM_DSP         : integer     := 1;
    -- Maximum number of registers replacable by a DSP
    NUM_REG_PER_DSP : integer     := 2
    );
  port (
    -- System clock
    CLK_I    : in  std_logic;
    -- Synchronous reset.
    RST_I    : in  std_logic;
    -- Enable Signal, currently unused.
    ENABLE_I : in  std_logic_vector(0 to NUM_ENABLE-1);
    ENABLE_O : out std_logic_vector(0 to NUM_ENABLE-1);
    -- Start signal marking the beginning of a new word.
    START_I  : in  std_logic_vector(0 to NUM_START-1);
    START_O  : out std_logic_vector(0 to NUM_START-1);
    -- Serial input of the N input words.
    STREAM_I : in  SLVArray(0 to N - 1)(SW - 1 downto 0);
    -- Serial output of the M output words.
    STREAM_O : out SLVArray(0 to N - 1)(SW - 1 downto 0)
    );

end entity Stage;

architecture BEHAVIORAL of Stage is

  pure function absolute(constant x : integer) return integer is
  begin
    if (x < 0) then
      return -1*x;
    else
      return x;
    end if;
  end absolute;

  constant NUM_REG : integer := NUM_DELAY*SW;

  constant NUM_REG_DSP     : integer := MINIMUM(NUM_REG, NUM_DSP * NUM_REG_PER_DSP);
  constant NUM_REG_DSP_DIV : integer := (NUM_REG_DSP / NUM_REG_PER_DSP);
  constant NUM_REG_DSP_REM : integer := NUM_REG_DSP mod NUM_REG_PER_DSP;
  signal dsp_dummy         : std_logic_vector(MAXIMUM(NUM_REG_PER_DSP - NUM_REG_DSP_REM - 1, 0) downto 0);
  signal dsp_reg_in        : std_logic_vector(MAXIMUM(NUM_REG_DSP-1, 0) downto 0);
  signal dsp_reg_out       : std_logic_vector(MAXIMUM(NUM_REG_DSP-1, 0) downto 0);

  constant NUM_REG_FF : integer := NUM_REG - NUM_REG_DSP;
  signal ff_reg_in    : std_logic_vector(MAXIMUM(NUM_REG_FF-1, 0) downto 0);
  signal ff_reg_out   : std_logic_vector(MAXIMUM(NUM_REG_FF-1, 0) downto 0);


  signal cs_out : SLVArray(0 to N -1)(SW-1 downto 0);
begin  -- architecture BEHAVIORAL

  -- Conditional genenration of enable registers.
  -- May be handled outside or not at all.
  ENABLEDELAY_GENERATE_IF : if NUM_ENABLE > 0 generate
    ENABLEDELAY : entity work.WordRegister
      generic map (
        W => NUM_ENABLE)
      port map (
        CLK_I    => CLK_I,
        RST_I    => '0',
        ENABLE_I => '1',
        D_I      => ENABLE_I,
        D_O      => ENABLE_O
        );
  end generate ENABLEDELAY_GENERATE_IF;

  -- The START signal is always required and hence not conditionally generated.
  STARTDELAY : entity work.WordRegister
    generic map (
      W => NUM_START)
    port map (
      CLK_I    => CLK_I,
      RST_I    => '0',
      ENABLE_I => '1',
      D_I      => START_I,
      D_O      => START_O
      );

  ------------------------------------------------------------------------------------------
  --CS Generation---------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  CS_GENERATE_FOR : for i in 0 to N -1 generate
    CS_GENERATE_IF : if absolute(PERM(i)) > i generate
      CS_GENERATE_INORDER : if PERM(i) > 0 generate

        SWCS_1 : entity work.SWCS
          generic map (
            SW => SW)
          port map (
            CLK_I   => CLK_I,
            A_I     => STREAM_I(PERM(i)),
            B_I     => STREAM_I(i),
            A_O     => cs_out(PERM(i)),
            B_O     => cs_out(i),
            START_I => START_I(i / (N/ NUM_START))
            );
      end generate CS_GENERATE_INORDER;
      CS_GENERATE_REVERSE : if PERM(i) < 0 generate

        SWCS_1 : entity work.SWCS
          generic map (
            SW => SW)
          port map (
            CLK_I   => CLK_I,
            A_I     => STREAM_I(PERM(i)),
            B_I     => STREAM_I(i),
            A_O     => cs_out(i),
            B_O     => cs_out(PERM(i)),
            START_I => START_I(i / (N/ NUM_START))
            );
      end generate CS_GENERATE_REVERSE;
    end generate CS_GENERATE_IF;
  end generate CS_GENERATE_FOR;
  ------------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------------
  --DSP Generation--------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  DSP_GENERATE_IF : if NUM_REG_DSP > 0 generate
    DSP_GENERATE_FOR : for i in 0 to NUM_REG_DSP_DIV-1 generate
      REGISTER_DSP_1 : entity work.REGISTER_DSP
        generic map (
          NUM_INPUTS    => NUM_REG_PER_DSP,
          REG_PER_INPUT => 1)
        port map (
          CLK_I    => CLK_I,
          RST_I    => '0',
          ENABLE_I => '1',
          REG_I    => dsp_reg_in((i+1)*NUM_REG_PER_DSP -1 downto i*NUM_REG_PER_DSP),
          REG_O    => dsp_reg_out((i+1)*NUM_REG_PER_DSP -1 downto i*NUM_REG_PER_DSP)
          );
    end generate DSP_GENERATE_FOR;
  end generate DSP_GENERATE_IF;

  DSP_GENERATE_REM : if NUM_REG_DSP_REM > 0 generate
    REGISTER_DSP_1 : entity work.REGISTER_DSP
      generic map (
        NUM_INPUTS    => NUM_REG_PER_DSP,
        REG_PER_INPUT => 1)
      port map (
        CLK_I                                           => CLK_I,
        RST_I                                           => '0',
        ENABLE_I                                        => '1',
        REG_I(NUM_REG_DSP_REM-1 downto 0)               => dsp_reg_in(NUM_REG_DSP -1 downto NUM_REG_DSP_DIV*NUM_REG_PER_DSP),
        REG_I(NUM_REG_PER_DSP-1 downto NUM_REG_DSP_REM) => (others => '0'),
        REG_O(NUM_REG_DSP_REM-1 downto 0)               => dsp_reg_out(NUM_REG_DSP -1 downto NUM_REG_DSP_DIV*NUM_REG_PER_DSP),
        REG_O(NUM_REG_PER_DSP-1 downto NUM_REG_DSP_REM) => dsp_dummy
        );
  end generate DSP_GENERATE_REM;
  ------------------------------------------------------------------------------------------


  ------------------------------------------------------------------------------------------
  --FF Generation---------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  FF_GENERATE_IF : if NUM_REG_FF > 0 generate
    FF_GENERATE_FOR : for i in 0 to NUM_REG_FF-1 generate
      WordRegister_1 : entity work.WordRegister
        generic map (
          W => 1)
        port map (
          CLK_I    => CLK_I,
          RST_I    => '0',
          ENABLE_I => '1',
          D_I(0)   => ff_reg_in(i),
          D_O(0)   => ff_reg_out(i)
          );
    end generate FF_GENERATE_FOR;
  end generate FF_GENERATE_IF;
  ------------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------------
  --Register Connection Process-------------------------------------------------------------
  --Used to connect registered inputs and outputs to the generated register representations.
  ------------------------------------------------------------------------------------------
  CONNECT_REG : process(STREAM_I, cs_out, dsp_reg_out, ff_reg_out) is
    variable reg_i : integer;
  begin
    reg_i := 0;
    for i in 0 to N - 1 loop
      if (absolute(PERM(i)) > i) then
        STREAM_O(i)       <= cs_out(i);
        STREAM_O(PERM(i)) <= cs_out(PERM(i));
      elsif( PERM(i) = i ) then
        for j in SW-1 downto 0 loop
          if reg_i < NUM_REG then
            if (reg_i < NUM_REG_DSP) then
              dsp_reg_in(reg_i) <= STREAM_I(i)(j);
              STREAM_O(i)(j)    <= dsp_reg_out(reg_i);
            else
              ff_reg_in(reg_i-NUM_REG_DSP) <= STREAM_I(i)(j);
              STREAM_O(i)(j)               <= ff_reg_out(reg_i-NUM_REG_DSP);
            end if;
            reg_i := reg_i + 1;
          end if;
        end loop;
      end if;
    end loop;
  end process;
  ------------------------------------------------------------------------------------------

end architecture BEHAVIORAL;
