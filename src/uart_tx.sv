`timescale 1ns/1ps

module transmitter #(
	parameter CLK_FREQ = 100_000_000,
	parameter BAUD_RATE = 1_000_000
) (
	input  logic       clk,
	input  logic       rstn,
	input  logic       data_en,
	input  logic [7:0] data_in,
	output logic       tx,
	output logic       tx_busy
);

	localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;

	// State machine states
	typedef enum logic [3:0] {
		STATE_IDLE  = 4'b0000,
		STATE_START = 4'b0001,
		STATE_BIT0  = 4'b0010,
		STATE_BIT1  = 4'b0011,
		STATE_BIT2  = 4'b0100,
		STATE_BIT3  = 4'b0101,
		STATE_BIT4  = 4'b0110,
		STATE_BIT5  = 4'b0111,
		STATE_BIT6  = 4'b1000,
		STATE_BIT7  = 4'b1001,
		STATE_STOP  = 4'b1010
	} state_t;

	state_t state, next_state;
	logic [7:0] data_reg;
	logic [19:0] bit_timer;

	// Output logic - combinational
	always_comb begin
		case (state)
			STATE_IDLE:  tx = 1'b1;           // Idle high
			STATE_START: tx = 1'b0;           // Start bit low
			STATE_BIT0:  tx = data_reg[0];
			STATE_BIT1:  tx = data_reg[1];
			STATE_BIT2:  tx = data_reg[2];
			STATE_BIT3:  tx = data_reg[3];
			STATE_BIT4:  tx = data_reg[4];
			STATE_BIT5:  tx = data_reg[5];
			STATE_BIT6:  tx = data_reg[6];
			STATE_BIT7:  tx = data_reg[7];
			STATE_STOP:  tx = 1'b1;           // Stop bit high
			default:     tx = 1'b1;
		endcase
	end

	// Busy signal
	assign tx_busy = (state != STATE_IDLE);

	// Sequential logic
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= STATE_IDLE;
			data_reg <= 8'b0;
			bit_timer <= 20'b0;
		end else begin
			state <= next_state;

			// Timer management
			if (bit_timer == CLOCKS_PER_BIT - 1) begin
				bit_timer <= 20'b0;
			end else begin
				bit_timer <= bit_timer + 1'b1;
			end

			// Latch input data on transition to START state
			if ((state == STATE_IDLE) && (next_state == STATE_START)) begin
				data_reg <= data_in;
			end
		end
	end

	// Next state logic
	always_comb begin
		next_state = state;

		case (state)
			STATE_IDLE: begin
				if (data_en) begin
					next_state = STATE_START;
				end
			end

			STATE_START: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT0;
				end
			end

			STATE_BIT0: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT1;
				end
			end

			STATE_BIT1: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT2;
				end
			end

			STATE_BIT2: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT3;
				end
			end

			STATE_BIT3: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT4;
				end
			end

			STATE_BIT4: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT5;
				end
			end

			STATE_BIT5: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT6;
				end
			end

			STATE_BIT6: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_BIT7;
				end
			end

			STATE_BIT7: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_STOP;
				end
			end

			STATE_STOP: begin
				if (bit_timer == CLOCKS_PER_BIT - 1) begin
					next_state = STATE_IDLE;
				end
			end

			default: begin
				next_state = STATE_IDLE;
			end
		endcase
	end

endmodule
