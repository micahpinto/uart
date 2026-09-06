`timescale 1ns / 1ps

module tb_uart_tx;

    parameter baud = 9600;
    parameter clk_freq = 100_000_000;
    parameter clk_period = (1_000_000_000 / clk_freq);
    parameter bit_period = (1_000_000_000 / baud);
    
    reg clk;
    reg rst_n;
    wire tx;
        
    uart_tx uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx(tx)
    );
    
    initial begin
        $dumpfile("uart_tx_waveform.vcd");
        $dumpvars(0, uut);
        
        clk = 0;
        forever #(clk_period/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        
        #(2_000_000);
        
        $finish;
    end

endmodule
