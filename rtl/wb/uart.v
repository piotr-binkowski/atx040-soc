module wb_uart(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, txd, rxd);

parameter  FIFO_DEPTH = 64;
parameter  BAUD_DIV   = 861;

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

output txd;
input rxd;

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

wire [7:0] status_reg;
wire status_sel;

wire [7:0] dat_o_mux;

assign dat_o = {dat_o_mux, 24'd0};

/* RX */

wire rx_full;
wire rx_empty;

wire [7:0] rx_din;
wire rx_write;

wire [7:0] rx_dout;
wire rx_read;

assign rx_read = (!status_sel) & ack_o & (!we_i);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(8)
) fifo_rx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(rx_write),
	.wdata(rx_din),
	.rd(rx_read),
	.rdata(rx_dout),
	.empty(rx_empty),
	.full(rx_full)
);

uart_rx #(
	.DIV(BAUD_DIV)
) uart_rx_i (
	.clk(clk_i),
	.rst(rst_i),
	.data(rx_din),
	.valid(rx_write),
	.rxd(rxd)
);

/* TX */

wire tx_full;
wire tx_empty;

wire [7:0] tx_din;
wire tx_write;

wire [7:0] tx_dout;
wire tx_read;

assign tx_din = dat_i[31:24];
assign tx_write = (!status_sel) & ack_o & we_i;

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(8)
) fifo_tx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(tx_write),
	.wdata(tx_din),
	.rd(tx_read),
	.rdata(tx_dout),
	.empty(tx_empty),
	.full(tx_full)
);

uart_tx #(
	.DIV(BAUD_DIV)
) uart_tx_i (
	.clk(clk_i),
	.rst(rst_i),
	.data(tx_dout),
	.valid(!tx_empty),
	.ready(tx_read),
	.txd(txd)
);

assign status_reg = {4'b0000, tx_full, tx_empty, rx_full, rx_empty};
assign dat_o_mux = (status_sel) ? status_reg : rx_dout;
assign status_sel = adr_i[0];

endmodule
