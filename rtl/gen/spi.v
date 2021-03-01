module spi(clk, rst, din, din_valid, din_ready, dout, dout_valid, dout_ready, sck, miso, mosi);

parameter DIV = 8;
parameter CW = $clog2(DIV*8);
parameter DW = 8;

input  clk;
input  rst;

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

parameter IDLE = 1'b0, BUSY = 1'b1;

reg state = IDLE;
reg valid = 1'b0;

assign din_ready = dout_ready & (state == IDLE);
assign dout_valid = valid;

always @(posedge clk) begin
	if (rst) begin
		cnt   <= 0;
		sck   <= 1'b0;
		state <= IDLE;
		data  <= {8{1'b0}};
		valid <= 1'b0;
	end else begin
		valid <= 1'b0;
		case(state)
			IDLE: begin
				if(din_ready & din_valid) begin
					data  <= din;
					state <= BUSY;
					cnt   <= 0;
				end
			end
			BUSY: begin
				cnt <= cnt + 1'b1;
				if((cnt % DIV) == 0) begin
					sck    <= 1'b1;
					miso_i <= miso;
				end else if ((cnt % DIV) == (DIV/2)) begin
					sck <= 1'b0;
					data <= {data[DW-2:0], miso_i};
				end
				if(cnt == (DIV*DW)) begin
					sck   <= 1'b0;
					valid <= 1'b1;
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
