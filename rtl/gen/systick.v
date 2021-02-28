module systick (
	input clk,
	input rst,
	output irq
);

parameter HZ = 100;
parameter CLK_FREQ = 100000000;
parameter CW = $clog2(CLK_FREQ/HZ);

reg [CW-1:0] cnt = {(CW){1'b0}};

assign irq = (cnt == (CLK_FREQ/HZ - 1));

always @(posedge clk)
	if (rst || irq)
		cnt <= {(CW){1'b0}};
	else
		cnt <= cnt + 1'b1;

endmodule
