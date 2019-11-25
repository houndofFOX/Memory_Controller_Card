library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.memory_module_top.all;
use work.global_package.all

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
    o_stop              : out std_logic
  );
end mem_card_top;

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

  constant ZERO_ADDR          : std_logic_vector(13 downto 0) := x"0000";
  constant ZEROS              : std_logic_vector(31 downto 0) := x"00000000";

---------------------- SIGNALS ----------------------
  signal s_addr             : std_logic_vector(31 downto 0);
  

process (i_clk) is

architecture mem_card_top of mem_card_top is
  
  type t_state is
    (
      IDLE,
      READ32_TA,
      READ32_WAIT,
      READ32,
      WRITE32_WAIT,
      WRITE32,
      READ64_TA,
      READ64_WAIT,
      READ64,
      WRITE64_WAIT,
      WRITE64,
      STOP_TERM
    );
  signal s_state : t_state;

begin
  -- State Machine
  stateMachine: process(i_reset, i_clk)
  begin
    if (i_reset = '1') then
      io_addr_data <= (others => '0');
      io_data_upper <= (others => '0');
      o_devsel_l <= '1';
      o_trdy_l <= '1';
      o_ack64_l <= '1';
      o_stop <= '1';
      s_state <= IDLE;
    elsif(rising_edge(i_clk)) then
      case s_state is
        when IDLE =>
          -- All PCI outputs in tristate until device is selected
          io_addr_data  <= (others => 'Z');
          io_data_upper <= (others => 'Z');
          o_devsel_l    <= 'Z';
          o_trdy_l      <= 'Z';
          o_ack64_l     <= 'Z';
          o_stop        <= 'Z';
          -- 
          s_addr      <= (others => '0');
          -- Wait for Frame assert
          if (i_frame_l = '0') then
            -- Check address
            if (io_addr_data(31 downto 18) = ZERO_ADDR and i_cbe_lower_l /= DUAL_ADDR_CYCLE) then
              -- Assert device select active
              o_devsel_l  <= '0';
              -- Assert TRDY inactive
              o_trdy_l    <= '1';
              -- Save addr to local register
              s_addr <= io_addr_data;
              -- Memory Read
              if (i_cbe_lower_l = MEM_READ) then
                -- 64 bit read mode
                if (i_req64_l = '0') then
                  o_ack64_l <= '0';
                  state <= READ64_TA;
                -- 32 bit read mode
                else
                  o_ack64_l <= '1';
                  state <= READ32_TA;
                end if;
              -- Memory Write
              elsif (i_cbe_lower_l = MEM_WRITE) then
                -- 64 bit write mode
                if(i_req64_l = '0') then
                  o_ack64_l <= '0';
                  state <= WRITE64_WAIT;
                -- 32 bit write mode
                else
                  o_ack64_l <= '1';
                  state <= WRITE32_WAIT;
                end if;
              else
                -- Issue stop, command not supported.
                o_stop <= '0';
                state <= STOP_TERM;
              end if;
            end if;
          end if;
        when READ64_TA =>
          -- o_trdy_l already set to high.
          -- o_devsel_l already set to low.
          state <= READ64_WAIT;
        when READ64_WAIT =>
          o_trdy_l <= '0';
          state <= READ64;
        when READ64 =>
          if (i_irdy_l = '0') then
            -- Bust Mode
            if (i_frame_l = '0') then

            -- End Transmission
            else
              -- Output signals need to be held for the last data xfer.
              -- Return to tristate on return to idle.
              state <= IDLE;
            end if;
          end if;
          
      end case;
    end if;
  end process;

  memory_module_top_inst_0 : entity work.memory_module_top
    port map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => io_addr_data (17 downto 3),
      io_data => io_addr_data(7 downto 0),
      i_cs => i_cbe_lower(0),
      i_oe => s_readnWrite,
      i_we => not s_readnWrite
    );
  
  memory_module_top_inst_1 : entity work.memory_module_top
    port_map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => io_addr_data(17 downto 3),
      io_data => io_addr_data(15 downto 8),
      i_cs => i_cbe_lower(1),
      i_oe => s_readnWrite,
      i_we => not s_readnWrite
    );
  
  memory_module_top_inst_2 : entity work.memory_module_top
    port_map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => io_addr_data(17 downto 3),
      io_data => io_addr_data(23 downto 16),
      i_cs => i_cbe_lower(2),
      i_oe => s_readnWrite,
      i_we => not s_readnWrite
    );

  memory_module_top_inst_3 : entity work.memory_module_top
    port_map
    (
      i_clk => i_clk,
      i_reset => i_reset,

      i_addr => io_addr_data(17 downto 3),
      io_data => io_addr_data(31 downto 24),
      i_cs => i_cbe_lower(3),
      i_oe => s_readnWrite,
      i_we => not s_readnWrite
    );
end architecture;