library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.std_logic_misc.all;


library work;
-- use work.memory_module_top.all;
use work.global_package.all;

entity mem_card_top is
  port
  (
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
end mem_card_top;

architecture mem_card_top of mem_card_top is
  
--------------------- CONSTANTS ---------------------
  -- PCI Commands
  constant INTERRUPT_ACK      : natural := 16#00#;
  constant SPECIAL_CYCLE      : natural := 16#01#;
  constant IO_READ            : natural := 16#02#;
  constant IO_WRITE           : natural := 16#03#;
  constant MEM_READ           : natural := 16#06#;
  constant MEM_WRITE          : natural := 16#07#;
  constant CFG_READ           : natural := 16#10#;
  constant CFG_WRITE          : natural := 16#11#;
  constant MEM_READ_MULTI     : natural := 16#12#;
  constant DUAL_ADDR_CYCLE    : natural := 16#13#;
  constant MEM_READ_LINE      : natural := 16#14#;
  constant MEM_WRTIE_INVAL    : natural := 16#15#;

  constant ZERO_ADDR          : std_logic_vector(13 downto 0) := "00000000000000";
  constant ZEROS              : std_logic_vector(31 downto 0) := x"00000000";

---------------------- SIGNALS ----------------------
  signal s_addr             : std_logic_vector(31 downto 0);
  signal s_readnWrite       : std_logic;    -- active high
  signal s_cs               : std_logic_vector(7 downto 0);  -- active high
  signal s_cs_addr          : std_logic_vector(7 downto 0);
  signal s_datas            : t_array_slv (0 to 7)(7 downto 0);
  signal s_enable_64        : std_logic;  -- active high

  type t_state is
    (
      IDLE,
      READ_TA,
      READ_WAIT,
      READ_M,
      WRITE_WAIT,
      WRITE_M,
      STOP_TERM
    );
  signal s_state : t_state;

begin
  -- Configure chip select
  process(i_reset, s_cs_addr, i_cbe_lower, i_cbe_upper) is
  begin
    if(i_reset = '1') then
      s_cs <= (others => '0');
    else
      -- 64 bit mode
      if (s_enable_64 = '1') then
        s_cs <= (s_cs_addr(7 downto 4) and i_cbe_upper) & (s_cs_addr(3 downto 0) and i_cbe_lower);
      -- 32 bit mode
      else
        s_cs <= (s_cs_addr(7 downto 4) and i_cbe_lower) & (s_cs_addr(3 downto 0) and i_cbe_lower);
      end if;
    end if;

  end process;

  -- State Machine
  process(i_reset, i_clk) is
  begin
    -- Check reset
    if (i_reset = '1') then
      -- Interfacing signals
      io_addr_data  <= (others => '0');
      io_data_upper <= (others => '0');
      o_devsel_l    <= '1';
      o_trdy_l      <= '1';
      o_ack64_l     <= '1';
      o_stop_l      <= '1';
      -- Internal signals
      s_addr        <= (others => '0');
      s_readnWrite  <= '1';
      s_cs_addr     <= (others => '0');
      for i in 0 to 7 loop
        s_datas(i) <= (others => '0');
      end loop;
      s_enable_64   <= '0';
      s_state       <= IDLE;
    -- Normal Operation
    elsif(rising_edge(i_clk)) then
      case s_state is
        when IDLE =>
          -- All PCI outputs in tristate until device is selected
          io_addr_data  <= (others => 'Z');
          io_data_upper <= (others => 'Z');
          o_devsel_l    <= 'Z';
          o_trdy_l      <= 'Z';
          o_ack64_l     <= 'Z';
          o_stop_l      <= 'Z';
          -- Set signal defaults
          s_addr        <= (others => '0');
          s_readnWrite  <= '1';
          s_cs_addr     <= (others => '0');
          s_enable_64   <= '0';
          -- Wait for Frame assert, check address and dual address mode
          if (i_frame_l = '0' and io_addr_data(31 downto 18) = ZERO_ADDR and i_cbe_lower_l /= DUAL_ADDR_CYCLE) then
            -- Configure outward facing signals
            -- o_stop_l default
            o_stop_l    <= '1';
            -- Assert device select active
            o_devsel_l  <= '0';
            -- Assert TRDY inactive
            o_trdy_l    <= '1';
            -- Set ACK64 output
            o_ack64_l   <= '0' when i_req64_l = '0' else '1';
            -- Configure internal signals
            -- Save addr to local register
            s_addr      <= io_addr_data(31 downto 3) & '000';
            -- Save 64 bit toggle
            s_enable_64 <= '1' when i_req64_l = '0' else '0';
            -- Memory Read
            if (i_cbe_lower_l = MEM_READ) then
              -- Set read not write
              s_readnWrite <= '1';
              -- Next state: Read Turnaround
              s_state <= READ_TA;
            -- Memory Write
            elsif (i_cbe_lower_l = MEM_WRITE) then
              -- Set not "read not write"
              s_readnWrite <= '0';
              -- Next State
              s_state <= WRITE_WAIT;
            -- Issue stop, command not supported.
            else
              o_stop_l <= '0';
              s_state <= STOP_TERM;
            end if;
          end if;
        -- READ Turnaround
        when READ_TA =>
          -- o_trdy_l already set to high.
          -- o_devsel_l already set to low.
          s_state <= READ_WAIT;
        -- READ wait state
        when READ_WAIT =>
          o_trdy_l <= '0';
          -- Set chip selects
          -- 64 bit
          if (i_req64_l = '0') then
            s_cs_addr <= (others => '1');
          -- 32 bit
          else
            s_cs_addr <= x"F0" when (s_addr(2) = '1') else x"0F";
          end if;
          s_state <= READ_M;
        when READ_M =>
          -- Check IRDY asserted, TRDY, DEVSEL controled by mem card
          if (i_irdy_l = '0') then
            -- Transmit data, load Data to PCI lines
            for i in 0 to 3 loop
              -- Lower 32 bits
              io_addr_data((8 * i + 7) downto (8 * i)) <= s_datas(i) when i_cbe_lower_l(i) = '0' else (others => '0');
              -- Upper 32 bits
              -- Byte enabled, load data
              io_data_upper((8 * i + 7) downto (8 * i)) <= s_datas(i + 4) when i_cbe_upper_l(i) = '0' else (others => '0');
            end loop;
            -- Bust Mode
            if (i_frame_l = '0') then
              -- Increment address
              s_addr <= std_logic_vector(unsigned(s_addr) + 8 when s_enable_64 = '1' else std_logic_vector(unsigned(s_addr) + 4;
              -- Hold bus in wait
              o_trdy <= '1';
              -- Return to wait state
              s_state <= READ64_WAIT;
            -- End Transmission w/ data
            else
              -- Set outputs to inactive to complete transmission
              -- Returns to tristate on return to idle.
              o_devsel_l <= '1';
              o_trdy_l <= '1';
              o_ack64_l <= '1';
              s_state <= IDLE;
            end if;
          end if;
        when STOP_TERM =>
          -- Wait for PCI termination protocol
          if (i_irdy_l = '0' and i_frame_l = '1') then
            s_state <= IDLE;
          end if;
      end case;
    end if;
  end process;

  memory_module_top_inst_0 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr (17 downto 3),
      io_data => s_datas(0),
      i_cs => s_cs(0),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
  
  memory_module_top_inst_1 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(1),
      i_cs => s_cs(1),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
  
  memory_module_top_inst_2 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(2),
      i_cs => s_cs(2),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );

  memory_module_top_inst_3 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(3),
      i_cs => s_cs(3),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
  memory_module_top_inst_4 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr (17 downto 3),
      io_data => s_datas(4),
      i_cs => s_cs(4),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
  
  memory_module_top_inst_5 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(5),
      i_cs => s_cs(5),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
  
  memory_module_top_inst_6 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(6),
      i_cs => s_cs(6),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );

  memory_module_top_inst_7 : entity work.memory_module_top
    port map
    (
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(7),
      i_cs => s_cs(7),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and s_state = WRITE_M and i_irdy_l = '0'
    );
end architecture;