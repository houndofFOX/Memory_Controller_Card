library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.std_logic_misc.all;


library work;
-- use work.memory_module_top.all;
use work.global_package.all;

entity memory_card_top is
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
end memory_card_top;

architecture memory_card_top of memory_card_top is
  
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
  constant MAX_ADDR           : std_logic_vector(14 downto 0) := (others => '1');
  constant MAX_WAIT           : integer := 7;

---------------------- SIGNALS ----------------------
  signal s_addr             : std_logic_vector(31 downto 0);
  signal s_readnWrite       : std_logic;    -- active high
  signal s_cs               : std_logic_vector(7 downto 0);  -- active high
  signal s_cs_addr          : std_logic_vector(7 downto 0);
  signal s_datas            : t_array_slv (0 to 7)(7 downto 0);
  signal s_enable_64        : std_logic;  -- active high
  signal s_wait_count       : integer range 0 to 7;

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
  process(i_reset, s_cs_addr, i_cbe_lower_l, i_cbe_upper_l) is
  begin
    if(i_reset = '1') then
      s_cs <= (others => '0');
    else
      -- 64 bit mode
      if (s_enable_64 = '1') then
        s_cs <= (s_cs_addr(7 downto 4) and not i_cbe_upper_l) & (s_cs_addr(3 downto 0) and not i_cbe_lower_l);
      -- 32 bit mode
      else
        s_cs <= (s_cs_addr(7 downto 4) and not i_cbe_lower_l) & (s_cs_addr(3 downto 0) and not i_cbe_lower_l);
      end if;
    end if;
  end process;

  -- Set address-based chip selects
  process(i_reset, s_state, i_frame_l, io_addr_data, i_cbe_lower_l) is
  begin
    if (i_reset = '1') then
      s_cs_addr <= (others => '0');
    else
      if (s_state = IDLE) then
        s_cs_addr <= (others => '0');
        if (i_frame_l = '0' and s_state /= IDLE and io_addr_data(31 downto 18) = ZERO_ADDR and i_cbe_lower_l /= DUAL_ADDR_CYCLE) then
          if (i_req64_l = '0') then
            s_cs_addr <= (others => '1');
          else
            s_cs_addr <= x"F0" when (io_addr_data(2) = '1') else x"0F";
          end if;
        end if;
      elsif (s_state = READ_WAIT or s_state = WRITE_WAIT) then
        -- 64 bit
        if (s_enable_64 = '1') then
          s_cs_addr <= (others => '1');
        -- 32 bit
        else
          s_cs_addr <= x"F0" when (s_addr(2) = '1') else x"0F";
        end if;
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
          -- Allow s_datas to be written to by default
          for i in 0 to 7 loop
            s_datas(i) <= (others => 'Z');
          end loop;
          -- Set signal defaults
          s_addr        <= (others => '0');
          s_readnWrite  <= '1';
          s_enable_64   <= '0';
          s_wait_count <= 0;
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
            s_addr      <= io_addr_data(31 downto 2) & "00";
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
              -- Control s_datas
              for i in 0 to 7 loop
                s_datas(i) <= (others => '0');
              end loop;
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
          -- Check for address overflow
          if (s_addr > MAX_ADDR) then
            o_stop_l <= '0';
            s_state <= STOP_TERM;
          -- Load Data to PCI lines
          else
            o_trdy_l <= '0';
            s_wait_count <= 0;
            for i in 0 to 3 loop
              if (s_enable_64 = '1') then
                -- Lower 32 bits
                io_addr_data((8 * i + 7) downto (8 * i)) <= s_datas(i) when i_cbe_lower_l(i) = '0' else (others => '0');
                -- Upper 32 bits
                -- Byte enabled, load data
                io_data_upper((8 * i + 7) downto (8 * i)) <= s_datas(i + 4) when i_cbe_upper_l(i) = '0' else (others => '0');
              else
                if (s_addr(2) = '0') then
                  io_addr_data((8 * i + 7) downto (8 * i)) <= s_datas(i) when i_cbe_lower_l(i) = '0' else (others => '0');
                else
                  io_addr_data((8 * i + 7) downto (8 * i)) <= s_datas(i + 4) when i_cbe_lower_l(i) = '0' else (others => '0');
                end if;
              end if;
            end loop;
            s_state <= READ_M;
          end if;
        when READ_M =>
          -- Check IRDY asserted, TRDY, DEVSEL controled by mem card
          if (i_irdy_l = '0') then
            -- Bust Mode
            if (i_frame_l = '0') then
              -- Increment address
              s_addr <= std_logic_vector(unsigned(s_addr) + 8) when s_enable_64 = '1' else std_logic_vector(unsigned(s_addr) + 4);
              -- Hold bus in wait
              o_trdy_l <= '1';
              -- Return to wait state
              s_state <= READ_WAIT;
            -- End Transmission w/ data
            else
              -- Set outputs to inactive to complete transmission
              -- Returns to tristate on return to idle.
              o_devsel_l <= '1';
              o_trdy_l <= '1';
              o_ack64_l <= '1';
              s_state <= IDLE;
            end if;
          else
            -- Timeout handling
            if (s_wait_count = MAX_WAIT) then
              io_addr_data <= (others => 'Z');
              io_data_upper <= (others => 'Z');
              o_trdy_l <= '1';
              o_stop_l <= '0';
              s_state <= STOP_TERM;
            elsif (s_wait_count < MAX_WAIT) then
              s_wait_count <= s_wait_count + 1;
            end if;
          end if;
        when WRITE_WAIT =>
          -- Check for address overflow
          if (s_addr > MAX_ADDR) then 
            o_stop_l <= '0';
            s_state <= STOP_TERM;
          else
            o_trdy_l <= '0';
            if (i_irdy_l = '0') then
              -- All values are populated in s_data, Chip Select determines what will be overwritten.
              for i in 0 to 3 loop
                -- 64 bit
                if (s_enable_64 = '1') then
                  -- Lower 32 bits
                  s_datas(i) <= io_addr_data((8 * i + 7) downto (8 * i));
                  -- Upper 32 bits
                  s_datas(i + 4) <= io_data_upper((8 * i + 7) downto (8 * i));
                -- 32 bit
                else
                  if (s_addr(2) = '0') then
                    s_datas(i) <= io_addr_data((8 * i + 7) downto (8 * i));
                  else
                    s_datas(i + 4) <= io_addr_data((8 * i + 7) downto (8 * i));
                  end if;
                end if;
              end loop;
              s_state <= WRITE_M;
            else
              --Timeout handling
              if (s_wait_count = MAX_WAIT) then
                io_addr_data <= (others => 'Z');
                io_data_upper <= (others => 'Z');
                o_trdy_l <= '1';
                o_stop_l <= '0';
                s_state <= STOP_TERM;
              elsif (s_wait_count < MAX_WAIT) then
                s_wait_count <= s_wait_count + 1;
              end if;
            end if;
          end if;
        when WRITE_M =>
          s_wait_count <= 0;
          -- Burst Mode
          if (i_frame_l = '0') then
            -- Increment address
            s_addr <= std_logic_vector(unsigned(s_addr) + 8) when s_enable_64 = '1' else std_logic_vector(unsigned(s_addr) + 4);
            -- Hold bus in wait
            o_trdy_l <= '1';
            -- Return to wait state
            s_state <= WRITE_WAIT;
          else
            -- Set outputs to inactive to complete transmission
            -- Returns to tristate on return to idle.
            o_devsel_l <= '1';
            o_trdy_l <= '1';
            o_ack64_l <= '1';
            s_state <= IDLE;
          end if;
        when STOP_TERM =>
          -- Wait for PCI termination protocol
          if (i_irdy_l = '0' and i_frame_l = '1') then
            o_stop_l <= '1';
            o_devsel_l <= '1';
            o_ack64_l <= '1';
            s_state <= IDLE;
          end if;
      end case;
    end if;
  end process;

  memory_module_top_inst_0 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr (17 downto 3),
      io_data => s_datas(0),
      i_cs => s_cs(0),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
  
  memory_module_top_inst_1 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(1),
      i_cs => s_cs(1),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
  
  memory_module_top_inst_2 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(2),
      i_cs => s_cs(2),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );

  memory_module_top_inst_3 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(3),
      i_cs => s_cs(3),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
  memory_module_top_inst_4 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr (17 downto 3),
      io_data => s_datas(4),
      i_cs => s_cs(4),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
  
  memory_module_top_inst_5 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(5),
      i_cs => s_cs(5),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
  
  memory_module_top_inst_6 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(6),
      i_cs => s_cs(6),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );

  memory_module_top_inst_7 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => s_addr(17 downto 3),
      io_data => s_datas(7),
      i_cs => s_cs(7),
      i_oe => s_readnWrite,
      i_we => (not s_readnWrite) and (not o_trdy_l) and (not i_irdy_l)
    );
end architecture;