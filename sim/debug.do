add wave -group "Testbench Signals" /memory_card_tb/s_clk
add wave -group "Testbench Signals" /memory_card_tb/s_reset
add wave -group "Testbench Signals" /memory_card_tb/s_frame_l
add wave -group "Testbench Signals" -radix Hexadecimal /memory_card_tb/s_addr_data
add wave -group "Testbench Signals" -radix Hexadecimal /memory_card_tb/s_data_upper
add wave -group "Testbench Signals" /memory_card_tb/s_cbe_lower_l
add wave -group "Testbench Signals" /memory_card_tb/s_cbe_upper_l
add wave -group "Testbench Signals" /memory_card_tb/s_irdy_l
add wave -group "Testbench Signals" /memory_card_tb/s_req64_l
add wave -group "Testbench Signals" /memory_card_tb/s_devsel_l
add wave -group "Testbench Signals" /memory_card_tb/s_trdy_l
add wave -group "Testbench Signals" /memory_card_tb/s_ack64_l
add wave -group "Testbench Signals" /memory_card_tb/s_stop

add wave -group "Memory Card Signals" /memory_card_tb/uut/i_clk
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_reset
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_frame_l
add wave -group "Memory Card Signals" -radix Hexadecimal /memory_card_tb/uut/io_addr_data
add wave -group "Memory Card Signals" -radix Hexadecimal /memory_card_tb/uut/io_data_upper
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_cbe_lower_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_cbe_upper_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_irdy_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/i_req64_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/o_devsel_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/o_trdy_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/o_ack64_l
add wave -group "Memory Card Signals" /memory_card_tb/uut/o_stop_l
add wave -group "Memory Card Signals" -radix Hexadecimal /memory_card_tb/uut/s_addr
add wave -group "Memory Card Signals" /memory_card_tb/uut/s_readnWrite
add wave -group "Memory Card Signals" /memory_card_tb/uut/s_cs
add wave -group "Memory Card Signals" /memory_card_tb/uut/s_cs_addr
add wave -group "Memory Card Signals" -radix Hexadecimal /memory_card_tb/uut/s_datas
add wave -group "Memory Card Signals" /memory_card_tb/uut/s_enable_64
add wave -group "Memory Card Signals" /memory_card_tb/uut/s_state

add wave -group "Memory Module 0" /memory_card_tb/uut/memory_module_top_inst_0/i_clk
add wave -group "Memory Module 0" /memory_card_tb/uut/memory_module_top_inst_0/i_reset
add wave -group "Memory Module 0" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_0/i_addr
add wave -group "Memory Module 0" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_0/io_data
add wave -group "Memory Module 0" /memory_card_tb/uut/memory_module_top_inst_0/i_cs
add wave -group "Memory Module 0" /memory_card_tb/uut/memory_module_top_inst_0/i_oe
add wave -group "Memory Module 0" /memory_card_tb/uut/memory_module_top_inst_0/i_we
add wave -group "Memory Module 0" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_0/s_memory_blk

add wave -group "Memory Module 1" /memory_card_tb/uut/memory_module_top_inst_1/i_clk
add wave -group "Memory Module 1" /memory_card_tb/uut/memory_module_top_inst_1/i_reset
add wave -group "Memory Module 1" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_1/i_addr
add wave -group "Memory Module 1" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_1/io_data
add wave -group "Memory Module 1" /memory_card_tb/uut/memory_module_top_inst_1/i_cs
add wave -group "Memory Module 1" /memory_card_tb/uut/memory_module_top_inst_1/i_oe
add wave -group "Memory Module 1" /memory_card_tb/uut/memory_module_top_inst_1/i_we
add wave -group "Memory Module 1" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_1/s_memory_blk

add wave -group "Memory Module 2" /memory_card_tb/uut/memory_module_top_inst_2/i_clk
add wave -group "Memory Module 2" /memory_card_tb/uut/memory_module_top_inst_2/i_reset
add wave -group "Memory Module 2" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_2/i_addr
add wave -group "Memory Module 2" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_2/io_data
add wave -group "Memory Module 2" /memory_card_tb/uut/memory_module_top_inst_2/i_cs
add wave -group "Memory Module 2" /memory_card_tb/uut/memory_module_top_inst_2/i_oe
add wave -group "Memory Module 2" /memory_card_tb/uut/memory_module_top_inst_2/i_we
add wave -group "Memory Module 2" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_2/s_memory_blk

add wave -group "Memory Module 3" /memory_card_tb/uut/memory_module_top_inst_3/i_clk
add wave -group "Memory Module 3" /memory_card_tb/uut/memory_module_top_inst_3/i_reset
add wave -group "Memory Module 3" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_3/i_addr
add wave -group "Memory Module 3" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_3/io_data
add wave -group "Memory Module 3" /memory_card_tb/uut/memory_module_top_inst_3/i_cs
add wave -group "Memory Module 3" /memory_card_tb/uut/memory_module_top_inst_3/i_oe
add wave -group "Memory Module 3" /memory_card_tb/uut/memory_module_top_inst_3/i_we
add wave -group "Memory Module 3" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_3/s_memory_blk

add wave -group "Memory Module 4" /memory_card_tb/uut/memory_module_top_inst_4/i_clk
add wave -group "Memory Module 4" /memory_card_tb/uut/memory_module_top_inst_4/i_reset
add wave -group "Memory Module 4" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_4/i_addr
add wave -group "Memory Module 4" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_4/io_data
add wave -group "Memory Module 4" /memory_card_tb/uut/memory_module_top_inst_4/i_cs
add wave -group "Memory Module 4" /memory_card_tb/uut/memory_module_top_inst_4/i_oe
add wave -group "Memory Module 4" /memory_card_tb/uut/memory_module_top_inst_4/i_we
add wave -group "Memory Module 4" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_4/s_memory_blk

add wave -group "Memory Module 5" /memory_card_tb/uut/memory_module_top_inst_5/i_clk
add wave -group "Memory Module 5" /memory_card_tb/uut/memory_module_top_inst_5/i_reset
add wave -group "Memory Module 5" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_5/i_addr
add wave -group "Memory Module 5" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_5/io_data
add wave -group "Memory Module 5" /memory_card_tb/uut/memory_module_top_inst_5/i_cs
add wave -group "Memory Module 5" /memory_card_tb/uut/memory_module_top_inst_5/i_oe
add wave -group "Memory Module 5" /memory_card_tb/uut/memory_module_top_inst_5/i_we
add wave -group "Memory Module 5" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_5/s_memory_blk

add wave -group "Memory Module 6" /memory_card_tb/uut/memory_module_top_inst_6/i_clk
add wave -group "Memory Module 6" /memory_card_tb/uut/memory_module_top_inst_6/i_reset
add wave -group "Memory Module 6" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_6/i_addr
add wave -group "Memory Module 6" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_6/io_data
add wave -group "Memory Module 6" /memory_card_tb/uut/memory_module_top_inst_6/i_cs
add wave -group "Memory Module 6" /memory_card_tb/uut/memory_module_top_inst_6/i_oe
add wave -group "Memory Module 6" /memory_card_tb/uut/memory_module_top_inst_6/i_we
add wave -group "Memory Module 6" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_6/s_memory_blk

add wave -group "Memory Module 7" /memory_card_tb/uut/memory_module_top_inst_7/i_clk
add wave -group "Memory Module 7" /memory_card_tb/uut/memory_module_top_inst_7/i_reset
add wave -group "Memory Module 7" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_7/i_addr
add wave -group "Memory Module 7" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_7/io_data
add wave -group "Memory Module 7" /memory_card_tb/uut/memory_module_top_inst_7/i_cs
add wave -group "Memory Module 7" /memory_card_tb/uut/memory_module_top_inst_7/i_oe
add wave -group "Memory Module 7" /memory_card_tb/uut/memory_module_top_inst_7/i_we
add wave -group "Memory Module 7" -radix Hexadecimal /memory_card_tb/uut/memory_module_top_inst_7/s_memory_blk



