`timescale 1ns / 1ps

module uart_tx (
    input clk,           // System clock 
    input rst_n,         // Active low reset 
    output reg tx        // UART TX output 
);

    // ===== PARAMETERS =====
    // Baud rate configuration
    parameter baud = 9600;                      // Transmission speed: 9600 bits per second
    parameter clk_freq = 100_000_000;           // System clock frequency: 100 MHz
    parameter clks_per_bit = clk_freq / baud;   // Clock cycles per bit: ~10,417 clocks
    parameter data = 8'hE2;                     // Data byte to transmit: 0xE2 (11100010 binary)

    // ===== STATE MACHINE STATES =====
    // Four states for UART transmission cycle
    parameter idle = 2'b00;                     // Waiting state, TX line held high
    parameter start_bit = 2'b01;                // Transmitting start bit (always 0)
    parameter data_bits = 2'b10;                // Transmitting 8 data bits (LSB first)
    parameter stop_bit = 2'b11;                 // Transmitting stop bit (always 1)

    // ===== INTERNAL REGISTERS =====
    reg [1:0] state;                            // Current FSM state
    reg [31:0] clock_counter;                   // Counts clock cycles within current bit period
    reg [2:0] bit_index;                        // Index of current data bit being transmitted (0-7)
    reg [7:0] tx_data;                          // Holds the data byte to be transmitted
   
    // ===== MAIN STATE MACHINE =====
    always @(posedge clk or negedge rst_n) begin
        // ===== ASYNCHRONOUS RESET =====
        if (!rst_n) begin
            // Reset all registers to initial state
            state <= idle;                      // Start in idle state
            clock_counter <= 0;                 // Clear clock counter
            bit_index <= 0;                     // Clear bit index
            tx <= 1'b1;                         // TX line idles high (inactive)
            tx_data <= data;                    // Load data byte to transmit
        end 
        
        // ===== SYNCHRONOUS STATE MACHINE =====
        else begin
            case (state)

                // ===== state: idle =====
                // TX line is held high (inactive).
                idle: begin
                    tx <= 1'b1;                 // Hold TX line high (idle state)
                    clock_counter <= 0;        // Reset clock counter for next bit
                    bit_index <= 0;            // Reset bit index for data bits
                    state <= start_bit;        // Transition to start bit state
                end

                // ===== state: start_bit =====
                start_bit: begin
                    tx <= 1'b0;                 // START bit is always 0 
                    
                    // Check if one complete bit period has elapsed
                    if (clock_counter == clks_per_bit - 1) begin
                        clock_counter <= 0;    // Reset counter for next bit
                        bit_index <= 0;        // Reset bit index before sending data bits
                        state <= data_bits;    // Transition to data bits state
                    end 
                    else begin
                        clock_counter <= clock_counter + 1;  // Increment counter
                    end
                end

                // ===== state: data_bits =====
                //Transmit 8 data bits, LSB (Least Significant Bit) first.
                // Each bit is held for one complete bit period (clks_per_bit clocks).
                //After all 8 bits are sent, transitions to stop_bit state.
                data_bits: begin
                    tx <= tx_data[bit_index];   // Output current data bit (LSB first)
                                                // bit_index selects which bit to send
                    
                    // Check if one complete bit period has elapsed
                    if (clock_counter == clks_per_bit - 1) begin
                        clock_counter <= 0;    // Reset counter for next bit
                        // Check if all 8 data bits have been sent
                        if (bit_index == 7) begin
                            // All 8 bits transmitted, move to stop_bit
                            bit_index <= 0;    // Reset for potential future use
                            state <= stop_bit; // Transition to stop bit state
                        end 
                        else begin
                            bit_index <= bit_index + 1;  // Move to next bit (0→1→2→...→7)
                        end
                    end 
                    else begin
                            clock_counter <= clock_counter + 1;  // Increment counter
                    end
                end

                // ===== state: stop_bit =====
                // Transmit the stop bit (always 1).
                 stop_bit: begin
                    tx <= 1'b1;                 // stop bit is always 1 
                   
                    if (clock_counter == clks_per_bit - 1) begin
                        // One bit period complete, frame transmission finished
                        clock_counter <= 0;    
                        state <= idle;         // Return to idle, ready to send next frame
                    end 
                    else begin
                        clock_counter <= clock_counter + 1;  // Increment counter
                    end
                end

                // ===== default state =====
                default: begin
                    state <= idle;             // Force return to idle
                    clock_counter <= 0;        // Clear counter
                    bit_index <= 0;            // Clear bit index
                    tx <= 1'b1;                // Set TX to idle high
                end

            endcase
        end
    end

endmodule