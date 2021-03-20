module stream_downsize(clk, rst, din_valid, din_ready, din, dout_valid, dout_ready, dout);

parameter DIN_DW = 32;
parameter DOUT_DW = 16;

localparam RATIO = DIN_DW/DOUT_DW;

parameter MW = $clog2(RATIO);

input  clk;
input  rst;

input  din_valid;
output din_ready;
input  [DIN_DW-1:0] din;

output dout_valid;
input  dout_ready;
output reg [DOUT_DW-1:0] dout;

reg [MW-1:0] mux;

integer i;

assign dout_valid = din_valid;
assign din_ready = dout_ready && (mux == (RATIO-1));

always @(*) begin
	dout = {(DOUT_DW){1'b0}};
	for(i = 0; i < RATIO; i = i+1) begin
		if(mux == i) begin
			dout = din[i*DOUT_DW+:DOUT_DW];
		end
	end
end

always @(posedge clk) begin
	if(rst) begin
		mux <= {(MW){1'b0}};
	end else if(dout_valid & dout_ready) begin
		mux <= mux + 1'b1;
		if(mux == (RATIO-1)) begin
			mux <= {(MW){1'b0}};
		end
	end
end

endmodule
