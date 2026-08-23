# uart_tx module implementation

# System Clock - 100 MHz
# Located at R2 on Arty S7-25 board
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Active Low Reset Button
# Located at C18 on Arty S7-25 board
# When button is pressed, rst_n = 0
set_property -dict { PACKAGE_PIN C18 IOSTANDARD LVCMOS33 } [get_ports rst_n]

# UART TX Output (to USB-UART converter)
# Located at R12 on Arty S7-25 board
set_property -dict { PACKAGE_PIN R12 IOSTANDARD LVCMOS33 } [get_ports tx]
 
