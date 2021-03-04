module wb_spi(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, sck, ss, miso, mosi);

parameter  FIFO_DEPTH = 1024;

localparam AW   = 2;
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
output reg ack_o;

output sck;
output reg ss;
input  miso;
output mosi;

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

wire [DW-1:0] status_reg;
wire status_sel;

wire dat_we;
wire dat_rd;

wire ctl_we;

(* keep = "true" *) wire tx_read;
(* keep = "true" *) wire [DW-1:0] tx_dout;
(* keep = "true" *) wire tx_empty;
(* keep = "true" *) wire tx_full;
(* keep = "true" *) wire tx_quad;
(* keep = "true" *) wire quad;

assign quad = (sel_i == 4'b1111);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW+1)
) fifo_tx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(dat_we),
	.wdata({quad, dat_i}),
	.rd(tx_read),
	.rdata({tx_quad, tx_dout}),
	.empty(tx_empty),
	.full(tx_full)
);

(* keep = "true" *) wire rx_write;
(* keep = "true" *) wire [DW-1:0] rx_din;
(* keep = "true" *) wire [DW-1:0] rx_rdata;
(* keep = "true" *) wire rx_empty;
(* keep = "true" *) wire rx_full;

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_rx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(rx_write),
	.wdata(rx_din),
	.rd(dat_rd),
	.rdata(rx_rdata),
	.empty(rx_empty),
	.full(rx_full)
);

spi spi_i (
	.clk(clk_i),
	.rst(rst_i),
	.quad(tx_quad),
	.din(tx_dout),
	.din_valid(!tx_empty),
	.din_ready(tx_read),
	.dout(rx_din),
	.dout_ready(!rx_full),
	.dout_valid(rx_write),
	.sck(sck),
	.miso(miso),
	.mosi(mosi)
);

assign dat_we = (!status_sel) & ack_o & we_i;
assign dat_rd = (!status_sel) & ack_o & (!we_i);

assign ctl_we = status_sel & ack_o & we_i;

assign status_reg = {5'd0, tx_full, rx_empty, ss, 24'd0};
assign dat_o = (status_sel) ? status_reg : rx_rdata;
assign status_sel = adr_i[0];

always @(posedge clk_i)
	if(rst_i)
		ss <= 1'b1;
	else if (ctl_we)
		ss <= dat_i[24];

endmodule
