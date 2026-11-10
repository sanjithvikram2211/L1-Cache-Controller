# Run from the L1_Cache_Controller_Modular project root:
# do sim/run.do
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog rtl/cache_address_decoder.v
vlog rtl/cache_tag_array.v
vlog rtl/cache_data_array.v
vlog rtl/cache_fsm.v
vlog rtl/cache_counter.v
vlog rtl/cache_controller.v
vlog rtl/cache_top.v
vlog tb/simple_memory.v
vlog tb/cache_controller_tb.v

vsim -voptargs=+acc work.cache_controller_tb

add wave -divider "CLOCK AND RESET"
add wave -radix binary sim:/cache_controller_tb/clk
add wave -radix binary sim:/cache_controller_tb/reset

add wave -divider "CPU INTERFACE"
add wave -radix binary sim:/cache_controller_tb/cpu_req
add wave -radix binary sim:/cache_controller_tb/cpu_we
add wave -radix hexadecimal sim:/cache_controller_tb/cpu_addr
add wave -radix hexadecimal sim:/cache_controller_tb/cpu_wdata
add wave -radix hexadecimal sim:/cache_controller_tb/cpu_rdata
add wave -radix binary sim:/cache_controller_tb/cpu_ready

add wave -divider "MEMORY INTERFACE"
add wave -radix binary sim:/cache_controller_tb/mem_req
add wave -radix binary sim:/cache_controller_tb/mem_we
add wave -radix hexadecimal sim:/cache_controller_tb/mem_addr
add wave -radix hexadecimal sim:/cache_controller_tb/mem_wdata
add wave -radix hexadecimal sim:/cache_controller_tb/mem_rdata
add wave -radix binary sim:/cache_controller_tb/mem_ready

add wave -divider "CACHE FSM"
add wave -radix unsigned sim:/cache_controller_tb/state_debug
add wave -radix unsigned sim:/cache_controller_tb/dut/controller/state
add wave -radix unsigned sim:/cache_controller_tb/dut/controller/next_state

add wave -divider "CACHE CONTROL"
add wave -radix binary sim:/cache_controller_tb/dut/controller/hit_pulse
add wave -radix binary sim:/cache_controller_tb/dut/controller/miss_pulse
add wave -radix hexadecimal sim:/cache_controller_tb/dut/controller/request_tag
add wave -radix unsigned sim:/cache_controller_tb/dut/controller/request_index
add wave -radix unsigned sim:/cache_controller_tb/dut/controller/request_word_offset

add wave -divider "CACHE STATISTICS"
add wave -radix unsigned sim:/cache_controller_tb/hit_count
add wave -radix unsigned sim:/cache_controller_tb/miss_count

add wave -divider "CACHE TAG ARRAY"
add wave -radix hexadecimal sim:/cache_controller_tb/dut/tag_array/tags
add wave -radix binary sim:/cache_controller_tb/dut/tag_array/valid
add wave -radix binary sim:/cache_controller_tb/dut/tag_array/dirty

add wave -divider "CACHE DATA ARRAY"
add wave -radix hexadecimal sim:/cache_controller_tb/dut/data_array/data

add wave -divider "MAIN MEMORY"
add wave -radix hexadecimal sim:/cache_controller_tb/memory_model/memory

configure wave -namecolwidth 280
configure wave -valuecolwidth 120
configure wave -timelineunits ns
update
run -all
