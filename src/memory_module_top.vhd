library ieee;
use iee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity memory_module_top is
    port
    (
        -- Clock/Reset
        i_clk       : in std_logic;
        i_reset     : in std_logic;

        -- Memory Module Control Signals
        i_addr      : in std_logic_vector(14 downto 0);
        io_data     : inout std_logic_vector(7 downto 0);
        i_cs        : in std_logic;
        i_oe        : in std_logic;
        i_we        : in std_logic
    );
end memory_module_top;


