library ieee;
use iee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.global_package.all

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

architecture memory_module_top of memory_module_top is
--------------------- CONSTANTS ---------------------
  constant c_memory_depth    : integer   := 32768;

---------------------- SIGNALS ----------------------
  signal s_memory_blk     : t_array_slv (0 to c_memory_depth - 1)(7 downto 0);

begin
  -- Reset
  process (i_reset) is
    if i_reset = '1' then
      -- Reset all memory values to 0
      for i in 0 to c_memory_depth - 1 loop
        s_memory_blk(i) <= (others => '0');
      end loop;
      -- TODO: Don't drive output lines, may need to change
      io_data <= (others => 'Z');
    end if;
  end process;
  
  process (i_clk) is
  begin
    if (rising_edge(i_clk)) then
      -- Allow memory card to drive io_data by default
      io_data <= (others => 'Z');
      -- Memory Read
      if (i_cs = '1' and i_oe = '1' and i_we = '0') then
        io_data <= s_memory_blk(i_addr);
      -- Memory Write
      elsif (i_cs = '1' and i_oe = '0' and i_we = '1') then 
        s_memory_blk(i_addr) <= io_data;
      end if;
    end if;
  end process;

end architecture;
