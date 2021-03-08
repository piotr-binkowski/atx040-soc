module bram_wsel (clk, wstrb, waddr, wdata, raddr, rdata);

parameter INIT = "";
parameter SIZE = 1024;
parameter COLS = 4;

parameter AW   = $clog2(SIZE);
parameter DW   = COLS*8;

input clk;

input [COLS-1:0] wstrb;
input [AW-1:0]   waddr;
input [DW-1:0]   wdata;

input      [AW-1:0] raddr;
output reg [DW-1:0] rdata;

reg [DW-1:0] mem [0:SIZE-1];

initial if(INIT) $readmemh(INIT, mem);

always @(posedge clk)
	rdata <= mem[raddr];

generate
	genvar i;
	for (i = 0; i < COLS; i = i+1) begin : byte_sel_gen
		always @(posedge clk) begin
			if (wstrb[i])
				mem[waddr][(i+1)*8-1: i*8] <= wdata[(i+1)*8-1:i*8];
		end
	end
endgenerate

endmodule

module bram (clk, wstrb, waddr, wdata, raddr, rdata);

parameter INIT = "";
parameter SIZE = 1024;

parameter AW   = $clog2(SIZE);
parameter DW   = 32;

input clk;

input wstrb;
input [AW-1:0] waddr;
input [DW-1:0] wdata;

input      [AW-1:0] raddr;
output reg [DW-1:0] rdata;

reg [DW-1:0] mem [0:SIZE-1];

initial if(INIT) $readmemh(INIT, mem);

always @(posedge clk)
	rdata <= mem[raddr];

always @(posedge clk)
	if (wstrb)
		mem[waddr] <= wdata;

endmodule
