module wb_spi(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, sck, ss, miso, mosi);

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

wire dat_ready;
wire [7:0] spi_dat_o;
wire spi_start;

wire dat_we;
wire ctl_we;

spi spi_i (
	.clk(clk_i),
	.rst(rst_i),
	.din(dat_i[31:24]),
	.din_valid(dat_we),
	.din_ready(dat_ready),
	.dout(spi_dat_o),
	.dout_ready(1'b1),
	.dout_valid(),
	.sck(sck),
	.miso(miso),
	.mosi(mosi)
);

assign dat_we = (!status_sel) & ack_o & we_i;
assign ctl_we = status_sel & ack_o & we_i;

assign status_reg = {6'b000000, !dat_ready, ss};
assign dat_o_mux = (status_sel) ? status_reg : spi_dat_o;
assign status_sel = adr_i[0];

always @(posedge clk_i)
	if(rst_i)
		ss <= 1'b1;
	else if (ctl_we)
		ss <= dat_i[24];

endmodule
