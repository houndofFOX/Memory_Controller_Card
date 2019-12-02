library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.global_package.all;

entity memory_module_top is
  port
  (
    -- Clock and Reset Memory
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
  -- TODO: io_data begin driven by multiple processes, consolidate

  -- Reset
  process (i_reset, i_cs, i_oe, i_we, i_clk) is
  begin
    if (i_reset = '1') then
      -- Reset all memory values to 0
      s_memory_blk(0) <= x"EF";
      s_memory_blk(1) <= x"BE";
      s_memory_blk(2) <= x"AD";
      s_memory_blk(3) <= x"DE";
      s_memory_blk(4) <= x"E2";
      s_memory_blk(5) <= x"AC";
      s_memory_blk(6) <= x"E1";
      s_memory_blk(7) <= x"AC";
      for i in 8 to c_memory_depth - 1 loop
        s_memory_blk(i) <= (others => '0');
      end loop;
      io_data <= (others => 'Z');
    else
      -- Memory read mode
      if (i_oe = '1' and i_we = '0') then
        io_data <= (others => '0');
        if (i_cs = '1') then
          io_data <= s_memory_blk(to_integer(unsigned(i_addr)));
        end if;
      end if;
      -- Memory write mode
      if (i_oe = '0' and i_we = '1') then
        io_data <= (others => 'Z');
        if(i_cs = '1') then
          if (rising_edge(i_clk)) then
            s_memory_blk(to_integer(unsigned(i_addr))) <= io_data;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture;
