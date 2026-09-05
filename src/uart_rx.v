`timescale 1ns / 1ps

module uart_rx (
    input clk,
    input rst_n,
    input rx,
    output reg [7:0] rx_data,
    output reg data_valid
);

    parameter baud = 9600;
    parameter clk_freq = 100_000_000;
    parameter clks_per_bit = clk_freq / baud;

    reg [2:0] state;
    reg [15:0] bit_counter;
    reg [3:0] bit_index;
    reg [7:0] shift_reg;
    reg rx_r, rx_rr;
   
    // Simple synchronizer
    always @(posedge clk) begin
        rx_r <= rx;
        rx_rr <= rx_r;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            bit_counter <= 0;
            bit_index <= 0;
            rx_data <= 0;
            data_valid <= 0;
            shift_reg <= 0;
        end else begin
           
            data_valid <= 0;  // Default: no valid data
           
            case (state)
                // State 0: IDLE
                0: begin
                    bit_counter <= 0;
                    if (rx_rr == 0) begin
                        state <= 1;  // START bit detected
                    end
                end
               
                // State 1: START bit
                1: begin
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == clks_per_bit - 1) begin
                        state <= 2;
                        bit_counter <= 0;
                        bit_index <= 0;
                    end
                end
               
                // State 2: DATA bits (8 bits)
                2: begin
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == clks_per_bit - 1) begin
                        shift_reg[bit_index] <= rx_rr;
                        bit_index <= bit_index + 1;
                        bit_counter <= 0;
                       
                        if (bit_index == 7) begin
                            state <= 3;
                        end
                    end
                end
               
                // State 3: STOP bit
                3: begin
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == clks_per_bit - 1) begin
                        rx_data <= shift_reg;
                        data_valid <= 1;
                        state <= 0;
                    end
                end
               
                default: state <= 0;
            endcase
        end
    end

endmodule
