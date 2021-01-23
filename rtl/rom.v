module wb_rom(clk, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o);

parameter INIT  = "";
parameter SIZE  = 1024;

parameter  AW   = $clog2(SIZE);
localparam DW   = 32;
localparam COLS = 4;

input clk;

input cyc_i;
input stb_i;
input we_i;
input [AW-1:0] adr_i;
input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output [DW-1:0] dat_o;
output reg ack_o = 1'b0;

bram #(
	.INIT(INIT),
	.SIZE(SIZE),
	.COLS(COLS)
) bram_i (
	.clk(clk),
	.wstrb(4'b0),
	.waddr(32'd0),
	.wdata(32'd0),
	.raddr(adr_i),
	.rdata(dat_o)
);

always @(posedge clk)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

endmodule

