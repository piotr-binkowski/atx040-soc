module wb_spi(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, sck, ss, miso, mosi);

parameter  FIFO_DEPTH = 64;

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

wire [7:0] status_reg;
wire status_sel;

wire [7:0] dat_o_mux;
assign dat_o = {dat_o_mux, 24'd0};

wire [7:0] spi_dat_o;

wire dat_we;
wire ctl_we;

wire tx_read;
wire [7:0] tx_dout;
wire tx_empty;
wire tx_full;

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(8)
) fifo_tx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(dat_we),
	.wdata(dat_i[31:24]),
	.rd(tx_read),
	.rdata(tx_dout),
	.empty(tx_empty),
	.full(tx_full)
);

spi spi_i (
	.clk(clk_i),
	.rst(rst_i),
	.din(tx_dout),
	.din_valid(!tx_empty),
	.dout(spi_dat_o),
	.dout_ready(1'b1),
	.dout_valid(),
	.din_ready(tx_read),
	.sck(sck),
	.miso(miso),
	.mosi(mosi)
);

assign dat_we = (!status_sel) & ack_o & we_i;
assign ctl_we = status_sel & ack_o & we_i;

assign status_reg = {6'b000000, !tx_read, ss};
assign dat_o_mux = (status_sel) ? status_reg : spi_dat_o;
assign status_sel = adr_i[0];

always @(posedge clk_i)
	if(rst_i)
		ss <= 1'b1;
	else if (ctl_we)
		ss <= dat_i[24];

endmodule
