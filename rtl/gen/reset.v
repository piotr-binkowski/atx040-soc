module reset_gen(
	input rstn,
	input clk,
	output reset
);

localparam RW = 32;

reg [3:0] rstn_d;

always @(posedge clk)
	rstn_d <= {rstn_d[2:0], rstn};

reg [RW-1:0] reset_shift = {(RW){1'b1}};

always @(posedge clk)
	if (rstn_d[3] == 1'b0)
		reset_shift <= {(RW){1'b1}};
	else
		reset_shift <= {reset_shift[RW-2:0], 1'b0};

assign reset = reset_shift[RW-1];

endmodule
