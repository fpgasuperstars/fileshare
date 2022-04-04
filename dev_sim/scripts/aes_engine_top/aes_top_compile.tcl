# ########################################################################################################
# modelsim compilation script for aes_engine_sbox
# ########################################################################################################
#  Creation : 21/02/2022 
#  Author(s): Jack O'Keefe

# ##################################################################################################################################
# Check if the script was called by the CI Server
# ##################################################################################################################################
if { [info exists CONTINUOUS_INTEGRATION] } {
  onerror { exit -code 171 }
}

# ##################################################################################################################################
# Set Path to RTL code
# ##################################################################################################################################
set PROJECT_PATH ../../..
set CODE_PATH    ../../../imp/code/devlib
set IP_PATH      ../../../imp/code/vendor

# Delete previous compilation
file delete -force comp_libraries
file mkdir comp_libraries

# ##################################################################################################################################
# LIBRARIES
# ##################################################################################################################################
# ==================================================================================================================================
# bram library
# ==================================================================================================================================
vlib comp_libraries/work
vlib comp_libraries/msim

vlib comp_libraries/msim/xpm
vlib comp_libraries/msim/blk_mem_gen_v8_4_5
vlib comp_libraries/msim/xil_defaultlib

vmap xpm comp_libraries/msim/xpm
vmap blk_mem_gen_v8_4_5 comp_libraries/msim/blk_mem_gen_v8_4_5
vmap xil_defaultlib comp_libraries/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu -sv \
"C:/Xilinx/Vivado/2021.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93 \
"C:/Xilinx/Vivado/2021.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work blk_mem_gen_v8_4_5  -incr -mfcu \
"../../../imp/code/vendor/aes_engine_key_bram/aes_engine_key_bram.gen/sources_1/bd/aes_engine_key_bram/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \

vcom -work xil_defaultlib  -93 \
"../../../imp/code/vendor/aes_engine_key_bram/aes_engine_key_bram.gen/sources_1/bd/aes_engine_key_bram/ip/aes_engine_key_bram_blk_mem_gen_0_0/synth/aes_engine_key_bram_blk_mem_gen_0_0.vhd" \

vlog -work xil_defaultlib \
"C:/git/aes_offload/dev_sim/scripts/aes_engine_bram/aes_engine_key_bram_blk_mem_gen_0_0/modelsim/glbl.v"  
# ==================================================================================================================================
# aes library
# ==================================================================================================================================
set lib_name aes_engine
vlib comp_libraries/$lib_name
vmap $lib_name comp_libraries/$lib_name

vcom -work $lib_name -2008 -explicit \
  $CODE_PATH/aes_engine/aes_engine_pkg.vhd\
  $CODE_PATH/aes_engine/aes_engine_round.vhd\
  $CODE_PATH/aes_engine/aes_engine_key_expansion.vhd\
  $CODE_PATH/aes_engine/aes_engine_top_sim.vhd