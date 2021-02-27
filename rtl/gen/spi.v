module spi(clk, rst, start, busy, dat_i, dat_o, sck, miso, mosi);

parameter DIV = 8;
parameter CW = $clog2(DIV*8);
parameter DW = 8;

input  clk;
input  rst;

input  start;
output busy;

input  [DW-1:0] dat_i;
output [DW-1:0] dat_o;

output reg sck;
input  miso;
output mosi;

reg [DW-1:0] data;

assign dat_o = data;
assign mosi  = data[DW-1];

reg miso_i;

reg [CW:0] cnt = 0;

parameter IDLE = 1'b0, BUSY = 1'b1;

reg state = IDLE;

assign busy = (state != IDLE);

always @(posedge clk) begin
	if (rst) begin
		state <= IDLE;
		cnt   <= 0;
		sck   <= 1'b0;
		data  <= {8{1'b0}};
	end else begin
		case(state)
			IDLE: begin
				if(start) begin
					data  <= dat_i;
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
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
