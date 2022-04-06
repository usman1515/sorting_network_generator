

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package CustomTypes is
    Subtype Word            is std_logic_vector;
    type SLVArray is array ( natural range <> ) of Word;
end CustomTypes;
