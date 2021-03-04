module wb_mem(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o);

parameter INIT = "";
parameter ROM  = "";
parameter SIZE = 1024;

parameter  AW   = $clog2(SIZE);
localparam DW   = 32;
localparam COLS = DW/8;

input clk_i;
input rst_i;

input cyc_i;
input stb_i;

input [AW-1:0] adr_i;
input we_i;

input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output [DW-1:0] dat_o;
output reg ack_o = 1'b0;

wire [COLS-1:0] wstrb;

assign wstrb = (ROM) ? 0 : (sel_i & {(COLS){we_i}} & {(COLS){ack_o}});

bram_wsel #(
	.INIT(INIT),
	.SIZE(SIZE),
	.COLS(COLS)
) bram_i (
	.clk(clk_i),
	.wstrb(wstrb),
	.waddr(adr_i),
	.wdata(dat_i),
	.raddr(adr_i),
	.rdata(dat_o)
);

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

endmodule

