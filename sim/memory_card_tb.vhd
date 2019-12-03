library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use work.global_package.all;

library std;
  use std.textio.all;

entity memory_card_tb is
end memory_card_tb;

architecture rtl of memory_card_tb is

  constant c_memory_depth : integer := 32768;
  constant c_cmd_read     : std_logic_vector(3 downto 0) := x"6";
  constant c_cmd_write    : std_logic_vector(3 downto 0) := x"7";
  constant MAX_ADDR       : std_logic_vector(14 downto 0) := (others => '1');

  component memory_card_top is
    port (
      -- Clocks and Resets
      i_clk       : in std_logic;
      i_reset     : in std_logic;

      -- PCI Control Signals
      i_frame_l           : in std_logic;
      io_addr_data        : inout std_logic_vector(31 downto 0);
      io_data_upper       : inout std_logic_vector(31 downto 0);
      i_cbe_lower_l       : in std_logic_vector(3 downto 0);
      i_cbe_upper_l       : in std_logic_vector(3 downto 0);
      i_irdy_l            : in std_logic;
      i_req64_l           : in std_logic;
      o_devsel_l          : out std_logic;
      o_trdy_l            : out std_logic;
      o_ack64_l           : out std_logic;
      o_stop_l            : out std_logic
    );
  end component;
  
  signal s_clk          : std_logic;
  signal s_reset        : std_logic;
  signal s_frame_l      : std_logic;
  signal s_addr_data    : std_logic_vector(31 downto 0);
  signal s_data_upper   : std_logic_vector(31 downto 0);
  signal s_cbe_lower_l  : std_logic_vector(3 downto 0);
  signal s_cbe_upper_l  : std_logic_vector(3 downto 0);
  signal s_irdy_l       : std_logic;
  signal s_req64_l      : std_logic;
  signal s_devsel_l     : std_logic;
  signal s_trdy_l       : std_logic;
  signal s_ack64_l      : std_logic;
  signal s_stop_l       : std_logic;


begin
  uut:memory_card_top port map(
    -- Clocks and Resets
    i_clk       => s_clk,
    i_reset     => s_reset,

    -- PCI Control Signals
    i_frame_l           => s_frame_l,
    io_addr_data        => s_addr_data,
    io_data_upper       => s_data_upper,
    i_cbe_lower_l       => s_cbe_lower_l,
    i_cbe_upper_l       => s_cbe_upper_l,
    i_irdy_l            => s_irdy_l,
    i_req64_l           => s_req64_l,
    o_devsel_l          => s_devsel_l,
    o_trdy_l            => s_trdy_l,
    o_ack64_l           => s_ack64_l,
    o_stop_l            => s_stop_l
  );

  -- Generate ~66MHz clk (actual 66.6666666MHz)
  pci_clk: process
  begin
    s_clk <= '1';
    wait for 15 ns;
    s_clk <= '0';
    wait for 15 ns;
  end process;

  stim: process
    procedure write32_single (i_addr : in std_logic_vector(31 downto 0); i_data : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      wait until(rising_edge(s_clk));
      s_addr_data <= i_data(31 downto 0);
      s_cbe_lower_l <= (others => '0');
      s_frame_l <= '1';
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0'); 
      s_addr_data <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure write32_single;

    procedure write32_burst (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      wait until(rising_edge(s_clk));
      s_addr_data <= x"ABC1ABC0";
      s_cbe_lower_l <= (others => '0');
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_addr_data <= x"ABC3ABC2";
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_addr_data <= x"ABC5ABC4";
      s_frame_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_addr_data <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure write32_burst;
  
    procedure write64_single (i_addr : in std_logic_vector(31 downto 0); i_data : in std_logic_vector(63 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => '0');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk));
      s_addr_data <= i_data(31 downto 0);
      s_data_upper <= i_data(63 downto 32);
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= (others => '0');
      s_frame_l <= '1';
      s_irdy_l <= '0';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0'); 
      s_addr_data <= (others => 'Z');
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure write64_single;

    procedure write64_burst (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => '0');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk));
      s_addr_data <= x"ACE3ACE2";
      s_data_upper <= x"ACE5ACE4";
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= (others => '0');
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_addr_data <= x"ACE7ACE6";
      s_data_upper <= x"ACE9ACE8";
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_addr_data <= x"ACEBACEA";
      s_data_upper <= x"ACEDACEC";
      s_frame_l <= '1';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_addr_data <= (others => 'Z');
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure write64_burst;

    procedure read32_single (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk)); -- ADDR, CMD, REQ64 read in
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      wait until(rising_edge(s_clk)); -- Turnaround
      s_frame_l <= '1';
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_cbe_lower_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure read32_single;

    procedure read32_burst (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk)); -- ADDR, CMD, REQ64 read in
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      wait until(rising_edge(s_clk)); -- Turnaround
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_frame_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_cbe_lower_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure read32_burst;

    procedure read64_single (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk)); -- ADDR, CMD, REQ64 read in
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= x"2";  -- CHIPSELECT DISABLED FOR SECOND BYTE
      wait until(rising_edge(s_clk)); -- Turnaround
      s_frame_l <= '1';
      s_irdy_l <= '0';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure read64_single;

    procedure read64_burst (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk)); -- ADDR, CMD, REQ64 read in
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= (others => '0');
      wait until(rising_edge(s_clk)); -- Turnaround
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_frame_l <= '1';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');  -- Data ready for transfer
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      s_irdy_l <= '1';
    end procedure read64_burst;

    -- 32 bit mode
    procedure write_timeout (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      wait until(rising_edge(s_clk));
      s_addr_data <= x"FFFFFFFF";
      s_cbe_lower_l <= (others => '0');
      wait until(rising_edge(s_clk) and s_stop_l = '0');
      s_frame_l <= '1';
      s_addr_data <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_irdy_l <= '0';
      wait until (rising_edge(s_clk));
      s_irdy_l <= '1';
    end procedure write_timeout;

    -- 64 bit mode
    procedure write_overflow is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data(31 downto 15) <= (others => '0');
      s_addr_data(14 downto 0) <= MAX_ADDR - x"F";
      s_data_upper <= (others => '0');
      s_cbe_lower_l <= c_cmd_write;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk));
      s_addr_data <= x"76543210";
      s_data_upper <= x"FEDCBA98";
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= (others => '0');
      s_irdy_l <= '0';
      wait until(rising_edge(s_clk) and s_trdy_l = '0');
      s_addr_data <= x"AAAABBBB";
      s_data_upper <= x"FACEBACE";
      wait until(rising_edge(s_clk) and s_stop_l = '0');
      s_frame_l <= '1';
      s_addr_data <= (others => 'Z');
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      s_req64_l <= '1';
      wait until(rising_edge(s_clk));
      s_irdy_l <= '1';
    end procedure write_overflow;
    
    -- 64 bit mode
    procedure read_timeout (i_addr : in std_logic_vector(31 downto 0)) is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data <= i_addr;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '0';
      wait until(rising_edge(s_clk));
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      s_cbe_upper_l <= (others => '0');
      wait until(rising_edge(s_clk) and s_stop_l = '0');
      s_frame_l <= '1';
      s_irdy_l <= '0';
      s_cbe_lower_l <= (others => '1');
      s_cbe_upper_l <= (others => '1');
      wait until(rising_edge(s_clk));
      s_req64_l <= '1';
      s_irdy_l <= '1';
    end procedure read_timeout;

    -- 32 bit mode
    procedure read_overflow is
    begin
      wait until(rising_edge(s_clk));
      s_frame_l <= '0';
      s_addr_data(31 downto 15) <= (others => '0');
      s_addr_data(14 downto 0) <= MAX_ADDR - 7;
      s_data_upper <= (others => 'Z');
      s_cbe_lower_l <= c_cmd_read;
      s_irdy_l <= '1';
      s_req64_l <= '1';
      wait until(rising_edge(s_clk)); -- ADDR, CMD, REQ64 read in
      s_addr_data <= (others => 'Z');  
      s_cbe_lower_l <= (others => '0');
      wait until(rising_edge(s_clk)); -- Turnaround
      s_irdy_l <= '0';
      wait until (rising_edge(s_clk) and s_stop_l = '0');
      s_cbe_lower_l <= (others => '1');
      s_frame_l <= '1';
      wait until(rising_edge(s_clk));  -- Data ready for transfer
      s_irdy_l <= '1';
    end procedure read_overflow;

  begin
    -- Set defaults, assume GNT from arbitor is received
    s_reset         <= '0';
    s_frame_l       <= '1';
    s_addr_data     <= (others => '0');
    s_data_upper    <= (others => '0');
    s_cbe_lower_l   <= (others => '1');
    s_cbe_upper_l   <= (others => '1');
    s_irdy_l        <= '1';
    s_req64_l       <= '1';

    -- Reset Memory card
    wait until(rising_edge(s_clk));
    s_reset <= '1';
    wait until(rising_edge(s_clk));
    s_reset <= '0';
    wait for 30 ns;
    write32_single(x"00000000", x"CAB1CAB0");
    wait for 50 ns;
    write32_burst(x"00000004");
    wait for 50 ns;
    write64_single(x"00000010", x"ACE1ACE0DEADBEEF");
    wait for 50 ns;
    write64_burst(x"00000018");
    wait for 50 ns;
    write_timeout(x"00000000");
    wait for 50 ns;
    write_overflow;
    wait for 50 ns;
    read32_single(x"00000010");
    wait for 50 ns;
    read32_burst(x"00000014");
    wait for 50 ns;
    read64_single(x"00000008");  -- Contains chipselect test
    wait for 50 ns;
    read64_burst(x"00000000");
    wait for 50 ns;
    read_timeout(x"00000010");
    wait for 50 ns;
    read_overflow;
    wait for 500 ms;
  end process;
end architecture;
