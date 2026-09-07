module receiver #(
	parameter CLOCKS_PER_PULSE = 10417
)
(
	input logic clk,
	input logic rstn,
	input logic ready_clr,
	input logic rx,
	output logic ready,
	output logic [7:0] data_out
);

	typedef enum logic [1:0] {
		IDLE   = 2'b00,
		START  = 2'b01,
		DATA   = 2'b10,
		STOP   = 2'b11
	} state_t;

	state_t state, next_state;
	logic [7:0] data_reg;
	logic [2:0] bit_count;
	logic [12:0] clk_count;
	logic rx_sync;
	logic rx_sync_d;

	// Synchronization
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			rx_sync <= 1'b1;
			rx_sync_d <= 1'b1;
		end else begin
			rx_sync_d <= rx;
			rx_sync <= rx_sync_d;
		end
	end

	// Main FSM
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			state <= IDLE;
			data_reg <= 8'b0;
			bit_count <= 3'b0;
			clk_count <= 13'b0;
			ready <= 1'b0;
		end else begin
			state <= next_state;

			if (clk_count == CLOCKS_PER_PULSE - 1) begin
				clk_count <= 13'b0;
			end else begin
				clk_count <= clk_count + 1'b1;
			end

			if ((state == DATA) && (clk_count == CLOCKS_PER_PULSE - 1)) begin
				data_reg[bit_count] <= rx_sync;
				if (bit_count == 3'd7) begin
					bit_count <= 3'b0;
				end else begin
					bit_count <= bit_count + 1'b1;
				end
			end

			if (ready_clr) begin
				ready <= 1'b0;
			end else if ((state == STOP) && (clk_count == CLOCKS_PER_PULSE - 1)) begin
				ready <= 1'b1;
			end
		end
	end

	// Next state logic
	always_comb begin
		next_state = state;

		case (state)
			IDLE: begin
				if (rx_sync == 1'b0) begin
					next_state = START;
				end
			end

			START: begin
				if (clk_count == (CLOCKS_PER_PULSE / 2 - 1)) begin
					next_state = DATA;
				end
			end

			DATA: begin
				if ((clk_count == CLOCKS_PER_PULSE - 1) && (bit_count == 3'd7)) begin
					next_state = STOP;
				end
			end

			STOP: begin
				if (clk_count == CLOCKS_PER_PULSE - 1) begin
					next_state = IDLE;
				end
			end

			default: begin
				next_state = IDLE;
			end
		endcase
	end

	assign data_out = data_reg;

endmodule
