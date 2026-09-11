`timescale 1ns/1ps

module transmitter_tb;

	localparam CLK_FREQ = 100_000_000;
	localparam BAUD_RATE = 1_000_000;
	localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
	localparam CLK_PERIOD = 10;
	localparam BIT_PERIOD = CLOCKS_PER_BIT * CLK_PERIOD;

	// DUT signals
	logic       clk;
	logic       rstn;
	logic       data_en;
	logic [7:0] data_in;
	logic       tx;
	logic       tx_busy;

	// Test signals
	int         bit_index;

	// Clock generation
	always #(CLK_PERIOD/2) clk = ~clk;

	// Instantiate DUT
	transmitter #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	) dut (
		.clk(clk),
		.rstn(rstn),
		.data_en(data_en),
		.data_in(data_in),
		.tx(tx),
		.tx_busy(tx_busy)
	);

	initial begin
		$dumpfile("transmitter.vcd");
		$dumpvars(0, transmitter_tb);

		$display("========================================");
		$display("UART Transmitter Testbench");
		$display("========================================");
		$display("Clock Frequency: %d Hz", CLK_FREQ);
		$display("Baud Rate: %d bps", BAUD_RATE);
		$display("Clocks Per Bit: %d", CLOCKS_PER_BIT);
		$display("Bit Period: %d ns", BIT_PERIOD);
		$display("========================================");
		$display("");

		// Initialize
		clk = 0;
		rstn = 0;
		data_en = 0;
		data_in = 8'h00;

		// Release reset
		#(CLK_PERIOD * 2);
		rstn = 1;
		#(CLK_PERIOD * 5);

		// Test frame 1: 0xAC (10101100)
		$display("[TEST 1] Sending: 0xAC (10101100)");
		send_and_verify(8'hAC);

		#(CLK_PERIOD * 10);

		// Test frame 2: 0x5A (01011010)
		$display("[TEST 2] Sending: 0x5A (01011010)");
		send_and_verify(8'h5A);

		#(CLK_PERIOD * 10);

		// Test frame 3: 0x3C (00111100)
		$display("[TEST 3] Sending: 0x3C (00111100)");
		send_and_verify(8'h3C);

		#(CLK_PERIOD * 10);

		// Test frame 4: 0xFF (11111111)
		$display("[TEST 4] Sending: 0xFF (11111111)");
		send_and_verify(8'hFF);

		#(CLK_PERIOD * 10);

		// Test frame 5: 0x00 (00000000)
		$display("[TEST 5] Sending: 0x00 (00000000)");
		send_and_verify(8'h00);

		$display("");
		$display("========================================");
		$display("All tests completed!");
		$display("========================================");
		#(CLK_PERIOD * 100);
		$finish();
	end

	// Task to send data and verify reception
	task send_and_verify(logic [7:0] test_data);
		logic [7:0] received_data;

		// Initiate transmission
		data_in = test_data;
		data_en = 1;
		#(CLK_PERIOD);
		data_en = 0;

		// Wait for transmission to start (START bit)
		wait (tx == 1'b0);
		$display("Frame started at time %t", $time);

		// Sample START bit
		#(BIT_PERIOD / 2);  // Wait to middle of START bit
		if (tx != 1'b0) begin
			$display("START bit error: expected 0, got %b", tx);
		end

		// Collect all 8 data bits
		for (bit_index = 0; bit_index < 8; bit_index++) begin
			#BIT_PERIOD;  // Wait for next bit
			received_data[bit_index] = tx;
			$display("Bit %d: %b", bit_index, tx);
		end

		// Sample STOP bit
		#BIT_PERIOD;
		if (tx != 1'b1) begin
			$display("  STOP bit error: expected 1, got %b", tx);
		end else begin
			$display("STOP bit: 1 (OK)");
		end

		// Verify received data
		if (received_data == test_data) begin
			$display("PASS - Received: 0x%02h", received_data);
			$display("");
		end else begin
			$display("FAIL - Expected: 0x%02h, Received: 0x%02h", test_data, received_data);
			$display("");
		end

		// Wait for transmission to complete and tx_busy to clear
		wait (tx_busy == 1'b0);
		$display("Transmission complete at time %t", $time);

	endtask

endmodule
