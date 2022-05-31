set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property PACKAGE_PIN W5 [get_ports fpgaclk]
set_property IOSTANDARD LVCMOS33 [get_ports fpgaclk]
create_clock -period 10.000 -waveform {0.000 5.000} [get_ports fpgaclk]

set_property PACKAGE_PIN A18 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

set_property PACKAGE_PIN B18 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_max_delay -from * -to * 5.000