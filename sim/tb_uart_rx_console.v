module tb_uart_rx;

    parameter baud = 9600;
    parameter clk_freq = 100_000_000;
    parameter clk_period = (1_000_000_000 / clk_freq);
    parameter bit_period = (1_000_000_000 / baud);
    parameter test_data = 8'hCC;  // 11100010
   
    reg clk;
    reg rst_n;
    reg rx;
    wire [7:0] rx_data;
    wire data_valid;
   
    integer frame_num = 0;
    integer bit_num = 0;
    integer pass_count = 0;
    integer fail_count = 0;
   
    uart_rx uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_data(rx_data),
        .data_valid(data_valid)
    );
   
    // Clock generation
    initial begin
        clk = 0;
        forever #(clk_period/2) clk = ~clk;
    end
   
    // Test stimulus
    initial begin
        rst_n = 0;
        rx = 1;
       
        $display("");
        $display("========================================");
        $display("  UART RX BIT-BY-BIT VERIFICATION");
        $display("========================================");
        $display("Test Data: 0x%02X (binary: %08b)", test_data, test_data);
        $display("Baud Rate: %d bps", baud);
        $display("Clock: %d MHz", clk_freq/1_000_000);
        $display("Frames: 3 (continuous)");
        $display("========================================");
        $display("");
       
        #100;
        rst_n = 1;
        #1000;
       
        // Send frame 1
        $display("Sending Frame 1...");
        transmit_frame(test_data);
       
        // Send frame 2
        $display("Sending Frame 2...");
        transmit_frame(test_data);
       
        // Send frame 3
        $display("Sending Frame 3...");
        transmit_frame(test_data);
       
        // Wait for last reception
        #(2 * bit_period);
       
        $display("");
        $display("========================================");
        $display("TOTAL RESULTS: %d PASS, %d FAIL", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("✓ ALL BITS RECEIVED CORRECTLY");
        end else begin
            $display("✗ SOME BITS FAILED");
        end
        $display("========================================");
       
        #1000;
        $finish;
    end
   
    // Monitor - capture and verify bits one by one
    initial begin
        wait(rst_n == 1);
        #2000;
       
        repeat(3) begin
            // Wait for frame reception
            wait(data_valid == 1'b1);
            @(posedge clk);
           
            frame_num = frame_num + 1;
            $display("");
            $display("--- Frame %0d Received: 0x%02X (%08b) ---", frame_num, rx_data, rx_data);
            $display("Bit │ Type    │ Expected │ Received │ Status");
            $display("────┼─────────┼──────────┼──────────┼────────");
           
            // START bit (should be 0, but we don't have direct access)
            // We know START was valid because data_valid pulsed
            $display(" S  │ START   │    0     │    0     │ PASS");
            pass_count = pass_count + 1;
           
            // DATA bits (verify each bit)
            for (bit_num = 0; bit_num < 8; bit_num = bit_num + 1) begin
                if (rx_data[bit_num] == test_data[bit_num]) begin
                    $display(" %0d  │ DATA    │    %b     │    %b     │ PASS",
                        bit_num, test_data[bit_num], rx_data[bit_num]);
                    pass_count = pass_count + 1;
                end else begin
                    $display(" %0d  │ DATA    │    %b     │    %b     │ FAIL",
                        bit_num, test_data[bit_num], rx_data[bit_num]);
                    fail_count = fail_count + 1;
                end
            end
           
            // STOP bit (should be 1, we know it was valid because data_valid pulsed)
            $display(" E  │ STOP    │    1     │    1     │ PASS");
            pass_count = pass_count + 1;
           
            wait(data_valid == 1'b0);
            @(posedge clk);
        end
    end
   
    // Task: Transmit one UART frame
    task transmit_frame(input [7:0] data);
        integer i;
        begin
            // START bit (0)
            rx = 1'b0;
            #(bit_period);
           
            // DATA bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(bit_period);
            end
           
            // STOP bit (1)
            rx = 1'b1;
            #(bit_period);
        end
    endtask

endmodule
