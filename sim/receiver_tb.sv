`timescale 1ns/1ps

module receiver_tb;

	localparam CLK_FREQ = 100_000_000;
	localparam BAUD_RATE = 1_000_000;
	localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
	localparam CLK_PERIOD = 10;
	localparam BIT_PERIOD = CLOCKS_PER_BIT * CLK_PERIOD;

	// Testbench signals
	logic clk;
	logic rstn;
	logic ready_clr;
	logic rx;
	logic ready;
	logic [7:0] data_out;

	// Test signals
	integer i;

	always #(CLK_PERIOD/2) clk = ~clk;

	receiver #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	) dut (
		.clk(clk),
		.rstn(rstn),
		.ready_clr(ready_clr),
		.rx(rx),
		.ready(ready),
		.data_out(data_out)
	);

	initial begin
		$dumpfile("receiver_waveform.vcd");
		$dumpvars(0, receiver_tb);

		clk = 0;
		rstn = 0;
		ready_clr = 0;
		rx = 1'b1;

		#20 rstn = 1;
		#(CLK_PERIOD * 200);

		// Test 1: 0xAC
		transmit_byte(8'hAC);
		#(BIT_PERIOD * 5);

		// Test 2: 0x5A
		transmit_byte(8'h5A);
		#(BIT_PERIOD * 5);

		// Test 3: 0xFF
		transmit_byte(8'hFF);
		#(BIT_PERIOD * 5);

		// Test 4: 0x00
		transmit_byte(8'h00);
		#(BIT_PERIOD * 5);

		#(BIT_PERIOD * 10);
		$finish();
	end

	task transmit_byte(logic [7:0] data);
		// START bit
		rx = 1'b0;
		#BIT_PERIOD;

		// 8 data bits (LSB first)
		for (i = 0; i < 8; i++) begin
			rx = data[i];
			#BIT_PERIOD;
		end

		// STOP bit
		rx = 1'b1;
		#BIT_PERIOD;

		// Wait for ready
		wait(ready == 1'b1);
		#(CLK_PERIOD * 5);

		// Clear ready
		ready_clr = 1;
		#(CLK_PERIOD * 2);
		ready_clr = 0;
	endtask

endmodule
