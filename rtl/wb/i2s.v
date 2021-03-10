module wb_i2s(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, irq, wsel, dout, bclk);

parameter FIFO_DEPTH = 4096;
parameter CW = $clog2(FIFO_DEPTH);

localparam DW = 32;
localparam COLS = DW/8;

input clk_i;
input rst_i;

input cyc_i;
input stb_i;

input adr_i;
input we_i;

input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output reg ack_o;
output [DW-1:0] dat_o;

output irq;

output wsel;
output dout;
output bclk;

reg [3:0] ctl_reg;

wire dat_we;
wire ctl_we;

wire fifo_rd;
wire fifo_empty;
wire [15:0] fifo_rdata;

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0;
	else
		ack_o <= stb_i;

assign dat_we = ack_o & we_i & adr_i;
assign ctl_we = ack_o & we_i & (!adr_i);

always @(posedge clk_i)
	if(rst_i)
		ctl_reg <= 4'd0;
	else if(ctl_we)
		ctl_reg <= dat_i[3:0];


assign dat_o = {28'd0, ctl_reg};

reg [CW-1:0] cnt = {(CW){1'b0}};

always @(posedge clk_i)
	if(rst_i)
		cnt <= {(CW){1'b0}};
	else if (cnt == (FIFO_DEPTH / 2))
		cnt <= {(CW){1'b0}};
	else
		cnt <= (fifo_rd & (!fifo_empty)) ? cnt + 1'b1 : cnt;

assign irq = (cnt == (FIFO_DEPTH / 2)) & ctl_reg[3];

i2s_tx i2s_i (
	.clk(clk_i),
	.rst(rst_i),
	.en(ctl_reg[0]),
	.ack(fifo_rd),
	.din(fifo_rdata),
	.mono(ctl_reg[1]),
	.fmt(ctl_reg[2]),
	.wsel(wsel),
	.dout(dout),
	.bclk(bclk)
);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(16)
) fifo_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(dat_we),
	.wdata(dat_i[31:16]),
	.rd(fifo_rd),
	.rdata(fifo_rdata),
	.empty(fifo_empty),
	.full()
);

endmodule
