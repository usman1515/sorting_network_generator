

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package CustomTypes is
    subtype Word            is std_logic_vector;
    type SLVArray is array ( natural range <> ) of std_logic_vector;

    type Permutation is array (natural range <>) of integer;
end CustomTypes;
