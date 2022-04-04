#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# sbox_run
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Store initial time
set t0 [clock clicks -millisec]
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Path Variables
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set PATH_BENCH        ../../code
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Create Simulation Libraries
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Delete previous Compilation
file delete -force tb_libraries
after 100
file mkdir tb_libraries

vlib tb_libraries/tb_lib
vmap tb_lib tb_libraries/tb_lib

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Primitives
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
vcom -2008 -work tb_lib $PATH_BENCH/aes_engine_tb_pkg.vhd
vcom -2008 -work tb_lib $PATH_BENCH/aes_engine_top/aes_engine_top_tb.vhd

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Simulation
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
vsim -voptargs=+acc -t 1ps -msgmode both tb_lib.aes_engine_top_tb

echo ::
echo ::
echo :: Simulation Started
echo ::
echo ::
if { ![info exists CONTINUOUS_INTEGRATION] } {
   do aes_top_wave.tcl
    log -r /*;  
}
#disable warning at time 0 for the to_integer lower down within the hierachy https://stackoverflow.com/questions/42181105/why-warning-numeric-std-to-integer-metavalue-detected-returning-0 for resolution
set NumericStdNoWarnings 1
run 0 ps
set NumericStdNoWarnings 0 
run -all

# Writes total run time
set seconds [expr {([clock clicks -millisec]-$t0)/1000.}]
puts [format "Simulation time : %.1f seconds (%.2f minutes)." $seconds [expr $seconds/60]]