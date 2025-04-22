set_property SRC_FILE_INFO {cfile:c:/Users/im121/Desktop/ece350project/snack_shack/snack_shack.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc rfile:../../../../../snack_shack.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
set_property SRC_FILE_INFO {cfile:C:/Users/im121/Desktop/ece350project/snack_shack/snack_shack.runs/clk_wiz_0_synth_1/dont_touch.xdc rfile:../../../dont_touch.xdc id:2} [current_design]
set_property src_info {type:SCOPED_XDC file:1 line:56 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 10.000 -name clk_in1 [get_ports clk_in1]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:60 export:INPUT save:INPUT read:READ} [current_design]
set_property PHASESHIFT_MODE WAVEFORM [get_cells mmcm_adv_inst]
current_instance
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name clkfbout_clk_wiz_0 -source [get_pins inst/mmcm_adv_inst/CLKIN1] -multiply_by 1 -add -master_clock [get_clocks clk_in1] [get_pins inst/mmcm_adv_inst/CLKFBOUT]
set_property src_info {type:PI file:{} line:-1 export:INPUT save:INPUT read:READ} [current_design]
create_generated_clock -name clk_out1_clk_wiz_0 -source [get_pins inst/mmcm_adv_inst/CLKIN1] -edges {1 2 3} -edge_shift {0.000 5.000 10.000} -add -master_clock [get_clocks clk_in1] [get_pins inst/mmcm_adv_inst/CLKOUT0]
set_property src_info {type:XDC file:2 line:9 export:INPUT save:INPUT read:READ} [current_design]
set_property KEEP_HIERARCHY SOFT [get_cells inst]
