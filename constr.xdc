create_clock -name clk -period 10 [get_ports clk]
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];

set_false_path -from [get_ports rst]

set_input_delay -clock clk -max 0.0 [get_ports {A_flat[*]}]
set_input_delay -clock clk -min 0.0 [get_ports {A_flat[*]}]

set_input_delay -clock clk -max 0.0 [get_ports {B_flat[*]}]
set_input_delay -clock clk -min 0.0 [get_ports {B_flat[*]}]
