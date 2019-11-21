library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.memory_module_top.all;

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
    o_ack64_l           : out std_logic
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

process (i_clk) is

architecture mem_card_top of mem_card_top is
  signal s_addr             : std_logic_vector(31 downto 0);
  signal s_addr_high        : std_logic_vector(31 downto 0);
  type t_state is
    (
      IDLE;
      DUAL_ADDR;
      READ32_TA
      READ32_WAIT
      READ32
      WRITE32_WAIT
      WRITE32
      READ64_TA
      READ64_WAIT
      READ64
    );
  signal s_state : t_state;

begin
  stateMachine: process(i_reset, i_clk)
  begin
    if (i_reset = '1') then
      io_addr_data <= (others => '0');
      io_data_upper <= (others => '0');
      o_devsel_l <= '1';
      o_trdy_1 <= '1';
      o_ack64_l <= '1';
      s_state <= IDLE;
    elsif(rising_edge(i_clk)) then
      case s_state is
        when IDLE =>
          io_addr_data  <= (others => 'Z');
          io_data_upper <= (others => 'Z');
          o_devsel_l    <= 'Z';
          o_trdy_1      <= 'Z';
          o_ack64_l     <= 'Z';
          s_addr      <= (others => '0');
          s_addr_high <= (others => '0');
          -- Wait for Frame assert
          if (i_frame_l = '0') then
            s_addr <= io_addr_data;
            -- Check Dual Addr (64-bit address) Mode
            if (i_cbe_lower_l = DUAL_ADDR_CYCLE) then
              s_state <= DUAL_ADDR;
            -- Regular 32-bit addressing
            else
              -- Check address
              if (io_addr_data(31 downto 18) = ZERO_ADDR) then
                o_devsel_l  <= '0';
                o_trdy_l    <= '1';
                -- Determine Read/Write
                if (i_cbe_lower_l = MEM_READ) then
                  -- 64 bit mode
                  if (i_req64_l = '0') then
                    o_ack64_l <= '0';
                    state <= READ64_TA;
                  else
                    o_ack64_l <= '1';
                    state <= READ32_TA;
                  end if;

                elsif (i_cbe_lower_l = MEM_WRITE) then
                  
                end if;
              end if;
            end if;
            
          end if;
        when DUAL_ADDR =>
          if (i_frame_l = '0') then
            s_addr_high <= io_addr_data;
            -- Check address
            if (io_addr_data(31 downto 18) = ZERO_ADDR and io_addr_data = ZEROS) then

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

      i_addr => io_addr_data_lower,
      io_data => 
    );
end architecture;