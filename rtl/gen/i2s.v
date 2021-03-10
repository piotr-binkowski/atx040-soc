module i2s_tx(clk, rst, en, ack, din, mono, fmt, wsel, dout, bclk);

parameter DIV = 35;
parameter CW = $clog2(DIV);

localparam DW = 16;

input  clk;
input  rst;

input  en;
output reg ack = 1'b0;
input  [DW-1:0] din;

input  mono;
input  fmt;

output reg wsel = 1'b0;
output dout;
output reg bclk = 1'b0;

wire [DW-1:0] din_i;
reg [DW-1:0] data    = {(DW){1'b0}};
reg [CW-1:0] clk_cnt = {(CW){1'b0}};
reg [4:0] bit_cnt    = 5'd0;
reg strobe           = 1'b0;

assign din_i = (fmt) ? din : {din[7:0], din[15:8]};

assign dout = data[DW-1];

always @(posedge clk) begin
	if(clk_cnt == DIV) begin
		strobe  <= 1'b1;
		clk_cnt <= {(CW){1'b0}};
	end else begin
		strobe  <= 1'b0;
		clk_cnt <= clk_cnt + 1'b1;
	end	
end

localparam IDLE = 1'b0, XFER = 1'b1;

reg ch = 1'b0;
reg state = IDLE;

always @(posedge clk) begin
	if(rst) begin
		state <= IDLE;
		ack   <= 1'b0;
		wsel  <= 1'b0;
		bclk  <= 1'b0;
	end else begin
		ack   <= 1'b0;
		if(strobe) begin
			case(state)
				IDLE: begin
					wsel    <= 1'b0;
					bclk    <= 1'b0;
					bit_cnt <= 5'd0;
					data    <= {(DW){1'b0}};
					state   <= (en) ? XFER : IDLE;
				end
				XFER: begin
					bit_cnt <= bit_cnt + 1'b1;
					if(bit_cnt == 5'd0) begin
						data <= din_i;
						ack  <= (!mono | ch) ? 1'b1 : 1'b0;
						bclk <= 1'b0;
					end else if((bit_cnt % 2) == 1'b1) begin
						bclk <= 1'b1;
					end else begin
						data <= {data[DW-2:0], 1'b0};
						bclk <= 1'b0;
					end

					wsel <= (bit_cnt == 5'd30) ? !wsel : wsel;

					if(bit_cnt == 5'd31) begin
						bit_cnt <= 5'd0;
						ch      <= !ch;
						state   <= (!en & ch) ? IDLE : XFER;
					end
				end
			endcase
		end
	end
end

endmodule
