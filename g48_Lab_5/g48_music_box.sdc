create_clock -period 20 [get_ports clk_50]
#*************************************************************************************************
# Set False Path for low speed outputs and the asynchronous inputs, as these are not time critical
#*************************************************************************************************
set_false_path -from {bpm[*]} -to {*}
set_false_path -from {start} -to {*}
set_false_path -from {looping} -to {*}
set_false_path -from {pause} -to {*}
set_false_path -from {stop} -to {*}
set_false_path -from {octave_i} -to {*}
set_false_path -from {init} -to {*}
set_false_path -from {reset} -to {*}
set_false_path -from {slct} -to {*}
set_false_path -from {*} -to {d*[*]}
set_false_path -from {*} -to {beat}
#********************************************************************************
# Set constraints for the Flash Memory I/O pins (these pins ARE time critical)
#*********************************************************************************
#Specify the clock period
set period 20.000
#Specify the required tSU
set tSU 10
#Specify the required tCO
set tCO 10
#
set_input_delay -clock clk_50 -max [expr $period - $tSU] [get_ports {FL_DQ[*]}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_DQ[*]}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_ADDR[*]}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_CE_N}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_OE_N}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_WE_N}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {FL_RST_N}]
#
#********************************************************************************
# Set constraints for the audio interface I/O pins (these pins ARE time critical)
#*********************************************************************************
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {AUD_MCLK}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {AUD_BCLK}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {AUD_DACDAT}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {AUD_DACLRCK}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {I2C_SDAT}]
set_output_delay -clock clk_50 -max [expr $period - $tCO] [get_ports {I2C_SCLK}]