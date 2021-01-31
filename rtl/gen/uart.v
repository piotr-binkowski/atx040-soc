module uart_tx(clk, rst, data, valid, ready, txd);

parameter DIV = 861;
parameter CW  = $clog2(DIV);

input clk;
input rst;

input [7:0] data;
input valid;
output reg ready = 1'b0;

output reg txd = 1'b1;

reg [CW-1:0] cnt = 0;
reg pulse = 1'b0;

always @(posedge clk) begin
	if(cnt < DIV) begin
		cnt   <= cnt + 1;
		pulse <= 0;
	end else begin
		cnt   <= 0;
		pulse <= 1;
	end
end


reg [3:0] tx_cnt = 4'd10;
reg [8:0] tx_reg;

always @(posedge clk) begin
	if (rst) begin
		txd   <= 1'b1;
		ready <= 1'b0;
	end else if ((tx_cnt == 4'd10)) begin
		txd   <= 1'b1;
		ready <= 1'b1;
		if (ready & valid) begin
			ready  <= 1'b0;
			tx_cnt <= 4'd0;
			tx_reg <= {data, 1'b0};
		end
	end else if (pulse == 1'b1) begin
		txd    <= tx_reg[0];
		tx_reg <= {1'b1, tx_reg[8:1]};
		tx_cnt <= tx_cnt + 1'b1;
	end
end

endmodule

module uart_rx(clk, rst, data, valid, rxd);

parameter DIV = 861;
parameter CW  = $clog2(DIV);

input clk;
input rst;

output reg [7:0] data;
output reg valid;

input rxd;

reg rxd_d;
reg rxd_dd;

wire rxd_i;
assign rxd_i = rxd_dd;

always @(posedge clk) begin
	if (rst) begin
		rxd_d  <= 1'b1;
		rxd_dd <= 1'b1;
	end else begin
		rxd_d  <= rxd;
		rxd_dd <= rxd_d;
	end
end

localparam IDLE = 2'd0, START = 2'd1, XFER = 2'd2, STOP = 2'd3;

reg [1:0] state = IDLE;

reg [CW-1:0] cnt = 0;
reg [2:0] bit = 0;

always @(posedge clk) begin
	if (rst) begin
		state <= IDLE;
		valid <= 1'b0;
		cnt   <= 0;
	end else begin
		valid <= 1'b0;
		cnt   <= cnt + 1'b1;
		case(state)
			IDLE: begin
				if (rxd_i == 1'b0) begin
					state <= START;
					data  <= 8'd0;
					cnt   <= 0;
				end
			end
			START: begin
				if (cnt == (DIV/2)) begin
					cnt   <= 0;
					bit   <= 0;
					state <= (rxd_i) ? IDLE : XFER;
				end
			end
			XFER: begin
				if (cnt == DIV) begin
					cnt   <= 0;
					bit   <= bit + 1'b1;
					data  <= {rxd_i, data[7:1]};
					state <= (bit == 3'd7) ? STOP : XFER;
				end
			end
			STOP: begin
				if (cnt == DIV) begin
					valid <= (rxd_i) ? 1'b1 : 1'b0;
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
