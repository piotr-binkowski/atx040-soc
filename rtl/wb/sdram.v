module wb_sdram(
	clk_i, rst_i,
	cyc_i, stb_i, adr_i, we_i,
	dat_i, sel_i, ack_o, dat_o,
	cke, cs, ras, cas, we,
	d, dm, a, ba
);

localparam AW   = 23;
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

output cke;
output cs;
output ras;
output cas;
output we;

inout [15:0] d;
output reg [1:0] dm;

output reg [ROW-1:0] a;
output reg [BANK-1:0] ba;

sdram sdram_i (
	.clk(clk_i),
	.rst(rst_i),

	.req_ready(),
	.req_valid(),
	.req_len(),
	.req_addr(),
	.req_dir(),

	.din(),
	.din_valid(),
	.din_ready(),
	.din_mask(),

	.dout(),
	.dout_valid(),

	.cke(cke),
	.cs(cs),
	.ras(ras),
	.cas(cas),
	.we(we),
	.data(d),
	.dm(dm),
	.addr(a),
	.baddr(ba)
);

endmodule
