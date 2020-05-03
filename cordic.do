setenv LMC_TIMEUNIT -9
vlib work
vmap work work
vcom -work work "fifo.vhd"
vcom -work work "cordic_stage.vhd"
vcom -work work "cordic.vhd"
vcom -work work "cordic_top.vhd"
vcom -work work "cordic_tb.vhd"

vsim +notimingchecks -L work work.cordic_tb -wlf cordic_sim.wlf

add wave -noupdate -group cordic_tb
add wave -noupdate -group cordic_tb -radix hexadecimal /cordic_tb/*
add wave -noupdate -group cordic_tb/cordic_top_inst
add wave -noupdate -group cordic_tb/cordic_top_inst -radix hexadecimal /cordic_tb/cordic_top_inst/*

add wave -noupdate -group cordic_tb/cordic_top_inst/cordic_inst
add wave -noupdate -group cordic_tb/cordic_top_inst/cordic_inst -radix hexadecimal /cordic_tb/cordic_top_inst/cordic_inst/*

add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_in
add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_in -radix hexadecimal /cordic_tb/cordic_top_inst/fifo_in/*

add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_out_cos
add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_out_cos -radix hexadecimal /cordic_tb/cordic_top_inst/fifo_out_cos/*

add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_out_sin
add wave -noupdate -group cordic_tb/cordic_top_inst/fifo_out_sin -radix hexadecimal /cordic_tb/cordic_top_inst/fifo_out_sin/*

run -all