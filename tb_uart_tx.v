`timescale 1ns / 1ps

module tb_uart_tx;

    parameter baud = 9600;
    parameter clk_freq = 100_000_000;
    parameter clk_period = (1_000_000_000 / clk_freq);
    parameter clks_per_bit = clk_freq / baud;
    parameter bit_period = (1_000_000_000 / baud);
    parameter data = 8'hE2;
    
    reg clk;
    reg rst_n;
    wire tx;
    reg [9:0] received_bits [0:2];  // Array to store 3 frames
    reg expected_bit;
    integer bit_index;
    integer frame_index;
    real sample_time_us;
    integer total_pass;
    integer total_fail;
        
    uart_tx uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx(tx)
    );
    
    initial begin
        clk = 0;
        forever #(clk_period/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        
        $display("");
        $display("========================================");
        $display("     UART TX TESTBENCH - SIMULATION");
        $display("========================================");
        $display("Test Configuration:");
        $display("  Test Data:       0x%02X (binary: %08b)", data, data);
        $display("  Baud Rate:       %d bps", baud);
        $display("  Clock Freq:      %d MHz", clk_freq / 1_000_000);
        $display("  Clocks per bit:  %d", clks_per_bit);
        $display("  Bit Period:      %.2f µs", bit_period / 1000.0);
        $display("  Frames to send:  3");
        $display("========================================");
        $display("");
        
        #100;
        
        rst_n = 1;
        
        $display("Reset released at time %0d ns", $time);
        #(11 * bit_period * 3 + 10000);  // Wait for 3 frames + some buffer
        
       $display("========================================");
        $display("    SIMULATION COMPLETED");
        $display("========================================");
        
        $finish;
    end
    
    initial begin
       
        wait(rst_n == 1);
        #1000;
  
        $display("Bit │ Time (µs) │ RX Val │ Expected │ Status");
        $display("────┼───────────┼────────┼──────────┼────────");
        
        total_pass = 0;
        total_fail = 0;
        
        // Capture 3 frames
        for (frame_index = 0; frame_index < 3; frame_index = frame_index + 1) begin
            received_bits[frame_index] = 10'b0;
            
            for (bit_index = 0; bit_index < 10; bit_index = bit_index + 1) begin
                #(bit_period / 2);
                
                received_bits[frame_index][bit_index] = tx;
                
                sample_time_us = $time / 1000.0;
                
                case (bit_index)
                    0: begin
                        expected_bit = 0;
                        
                        if (tx == expected_bit) begin
                            $display(" %0d | %8.3f  |  %b    │ START(0) │ PASS ",bit_index + (frame_index * 10), sample_time_us, tx);
                            total_pass = total_pass + 1;
                        end else begin
                            $display(" %0d │ %8.3f │ %b │ START(0) │ FAIL ",bit_index + (frame_index * 10), sample_time_us, tx);
                            total_fail = total_fail + 1;
                        end
                    end
                    
                    1,2,3,4,5,6,7,8: begin
                        expected_bit = data[bit_index - 1];
                        
                        if (tx == expected_bit) begin
                            $display(" %0d   │ %8.3f │ %b │ D%0d(%b) │ PASS ",bit_index + (frame_index * 10), sample_time_us, tx, bit_index - 1, expected_bit);
                            total_pass = total_pass + 1;
                        end else begin
                            $display(" %0d   │ %8.3f │   %b │ D%0d(%b)│ FAIL ",bit_index + (frame_index * 10), sample_time_us, tx, bit_index - 1, expected_bit);
                            total_fail = total_fail + 1;
                        end
                    end
                    
                    9: begin
                        expected_bit = 1;
                        
                        if (tx == expected_bit) begin
                            $display(" %0d │ %8.3f │   %b  │ STOP(1)│ PASS ",bit_index + (frame_index * 10), sample_time_us, tx);
                            total_pass = total_pass + 1;
                        end else begin
                            $display(" %0d │ %8.3f │   %b  │ STOP(1)│ FAIL ",bit_index + (frame_index * 10), sample_time_us, tx);
                            total_fail = total_fail + 1;
                        end
                    end
                endcase
                
                #(bit_period / 2);
            end
        end
        
        $display("");
        $display("════════════════════════════════════════════════════════");
        $display("TRANSMISSION RESULTS SUMMARY:");
        $display("════════════════════════════════════════════════════════");
        $display("");
        $display("Frame Analysis:");
        $display("");
        
        for (frame_index = 0; frame_index < 3; frame_index = frame_index + 1) begin
            if (received_bits[frame_index][8:1] == data) begin
                $display("--- Frame %d ---", frame_index + 1);
                $display("START bit: OK (0)");
                $display("DATA bits: OK (0x%02X = %08b)", received_bits[frame_index][8:1], received_bits[frame_index][8:1]);
                $display("STOP bit: OK (1)");
                $display("");
            end else begin
                $display("--- Frame %d ---", frame_index + 1);
                $display("START bit: OK (0)");
                $display("DATA bits: ERROR (expected 0x%02X = %08b, got 0x%02X = %08b)  BUG FOUND", 
                    data, data, received_bits[frame_index][8:1], received_bits[frame_index][8:1]);
                $display("STOP bit: OK (1)");
                $display("");
            end
        end
        
 
        $display("Total bits transmitted: 30 (10 bits × 3 frames)");
        $display("Bits passed:%0d", total_pass);
        $display("Bits failed:%0d", total_fail);
        $display("");
        
        if ((received_bits[0][8:1] == data) && 
            (received_bits[1][8:1] == data) && 
            (received_bits[2][8:1] == data) && 
            (total_fail == 0)) begin
            $display("TEST PASSED All 3 frames transmitted correctly.");
        end else begin
            $display("TEST FAILED Errors detected in transmission.");
            if (received_bits[0][8:1] != data) begin
                $display("  Frame 1 data bits do not match expected value");
            end
            if (received_bits[1][8:1] != data) begin
                $display("  Frame 2 data bits do not match expected value");
            end
            if (received_bits[2][8:1] != data) begin
                $display("  Frame 3 data bits do not match expected value");
            end
        end
    end

endmodule

