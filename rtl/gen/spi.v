module spi(clk, rst, quad, din, din_valid, din_ready, dout, dout_valid, dout_ready, sck, miso, mosi);

parameter DIV = 4;
parameter DW = 32;
parameter CW = $clog2(DIV*DW);

input  clk;
input  rst;

input  quad;

input  [DW-1:0] din;
input  din_valid;
output din_ready;

output [DW-1:0] dout;
output dout_valid;
input  dout_ready;

output reg sck;
input  miso;
output mosi;

reg [DW-1:0] data;

assign dout = data;
assign mosi = data[DW-1];

reg miso_i;

reg [CW:0] cnt = 0;

wire [CW:0] tgt;

parameter IDLE = 2'd0, BUSY = 2'd1, ACK = 2'd2;

reg [1:0] state = IDLE;
reg valid  = 1'b0;
reg quad_i = 1'b0;

assign din_ready = dout_ready & (state == IDLE);
assign dout_valid = valid;

assign tgt = (quad_i) ? (DIV*32) : (DIV*8);

always @(posedge clk) begin
	if (rst) begin
		cnt    <= 0;
		sck    <= 1'b0;
		state  <= IDLE;
		data   <= {(DW){1'b0}};
		valid  <= 1'b0;
		quad_i <= 1'b0;
	end else begin
		case(state)
			IDLE: begin
				if(din_ready & din_valid) begin
					cnt    <= 0;
					data   <= din;
					state  <= BUSY;
					quad_i <= quad;
				end
			end
			BUSY: begin
				cnt <= cnt + 1'b1;
				if((cnt % DIV) == 0) begin
					sck    <= 1'b1;
					miso_i <= miso;
				end else if ((cnt % DIV) == (DIV/2)) begin
					sck  <= 1'b0;
					data <= {data[DW-2:0], miso_i};
				end
				if(cnt == tgt) begin
					sck   <= 1'b0;
					valid <= 1'b1;
					state <= ACK;
				end
			end
			ACK: begin
				valid <= 1'b1;
				if (dout_valid & dout_ready) begin
					valid <= 1'b0;
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
