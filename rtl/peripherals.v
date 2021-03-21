module peripherals(
	clk, rst,
	req_valid, req_ready,
	req_len, req_mask, req_addr, req_we, req_wrap,
	write_valid, write_data,
	read_valid, read_ack, read_data,
	uart_txd, uart_rxd,
	eth_sck, eth_cs, eth_miso, eth_mosi, eth_int,
	flash_sck, flash_cs, flash_miso, flash_mosi,
	sd_sck, sd_cs, sd_miso, sd_mosi,
	i2s_wsel, i2s_dout, i2s_bclk,
	irq_req, irq_vec, irq_ack
);

input clk;
input rst;

input  req_valid;
output req_ready;
input  [2:0] req_len;
input  [3:0] req_mask;
input  [31:0] req_addr;
input  req_we;
input  req_wrap;

input  write_valid;
input  [31:0] write_data;

output read_valid;
input  read_ack;
output [31:0] read_data;

output uart_txd;
input  uart_rxd;

output eth_sck;
output eth_cs;
input  eth_miso;
output eth_mosi;
input  eth_int;

output flash_sck;
output flash_cs;
input  flash_miso;
output flash_mosi;

output sd_sck;
output sd_cs;
input  sd_miso;
output sd_mosi;

output i2s_wsel;
output i2s_dout;
output i2s_bclk;

output irq_req;
output [7:0] irq_vec;
input  irq_ack;

wire i2s_irq;
wire uart_irq;
wire systick_irq;

wire cyc_o;
wire stb_o;
wire ack_i;
wire we_o;
wire [3:0] sel_o;
wire [29:0] adr_o;
wire [31:0] dat_o;
wire [31:0] dat_i;

req_wb_bridge bridge_i (
	.clk_i(clk),
	.rst_i(rst),

	.req_valid(req_valid),
	.req_ready(req_ready),
	.req_len(req_len),
	.req_mask(req_mask),
	.req_addr(req_addr),
	.req_we(req_we),
	.req_wrap(req_wrap),

	.write_valid(write_valid),
	.write_data(write_data),

	.read_valid(read_valid),
	.read_ack(read_ack),
	.read_data(read_data),

	.wb_cyc_o(cyc_o),
	.wb_stb_o(stb_o),
	.wb_ack_i(ack_i),
	.wb_we_o(we_o),
	.wb_sel_o(sel_o),
	.wb_adr_o(adr_o),
	.wb_dat_o(dat_o),
	.wb_dat_i(dat_i)
);

wire        rom_stb, uart_stb, flash_stb, timer_stb, sd_stb, eth_stb, irqc_stb, i2s_stb;
wire        rom_ack, uart_ack, flash_ack, timer_ack, sd_ack, eth_ack, irqc_ack, i2s_ack;
wire [31:0] rom_dat, uart_dat, flash_dat, timer_dat, sd_dat, eth_dat, irqc_dat, i2s_dat;

wb_decoder #(
	.SLAVES(8),
	.SW(4)
) decoder_i (
	.stb_i(stb_o),
	.adr_i(adr_o[25:22]),
	.ack_o(ack_i),
	.dat_o(dat_i),
	.slv_stb_o({i2s_stb, irqc_stb, eth_stb, sd_stb, timer_stb, flash_stb, uart_stb, rom_stb}),
	.slv_ack_i({i2s_ack, irqc_ack, eth_ack, sd_ack, timer_ack, flash_ack, uart_ack, rom_ack}),
	.slv_dat_i({i2s_dat, irqc_dat, eth_dat, sd_dat, timer_dat, flash_dat, uart_dat, rom_dat})
);

wb_mem #(
	.ROM("TRUE"),
	.SIZE(64),
	.INIT("rom.mem")
) rom_i (
	.clk_i(clk),
	.rst_i(rst),

	.cyc_i(cyc_o),
	.stb_i(rom_stb),

	.we_i(we_o),
	.adr_i(adr_o[5:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(rom_ack),
	.dat_o(rom_dat)
);

wb_uart uart_i (
	.clk_i(clk),
	.rst_i(rst),

	.txd(uart_txd),
	.rxd(uart_rxd),

	.irq(uart_irq),

	.cyc_i(cyc_o),
	.stb_i(uart_stb),

	.we_i(we_o),
	.adr_i(adr_o[1:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(uart_ack),
	.dat_o(uart_dat)
);

wb_spi flash_i (
	.clk_i(clk),
	.rst_i(rst),
	.sck(flash_sck),
	.ss(flash_cs),
	.miso(flash_miso),
	.mosi(flash_mosi),

	.cyc_i(cyc_o),
	.stb_i(flash_stb),

	.we_i(we_o),
	.adr_i(adr_o[1:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(flash_ack),
	.dat_o(flash_dat)
);

wb_spi sd_i (
	.clk_i(clk),
	.rst_i(rst),
	.sck(sd_sck),
	.ss(sd_cs),
	.miso(sd_miso),
	.mosi(sd_mosi),

	.cyc_i(cyc_o),
	.stb_i(sd_stb),

	.we_i(we_o),
	.adr_i(adr_o[1:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(sd_ack),
	.dat_o(sd_dat)
);

wb_spi eth_i (
	.clk_i(clk),
	.rst_i(rst),
	.sck(eth_sck),
	.ss(eth_cs),
	.miso(eth_miso),
	.mosi(eth_mosi),

	.cyc_i(cyc_o),
	.stb_i(eth_stb),

	.we_i(we_o),
	.adr_i(adr_o[1:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(eth_ack),
	.dat_o(eth_dat)
);

wb_tim timer_i (
	.clk_i(clk),
	.rst_i(rst),

	.cyc_i(cyc_o),
	.stb_i(timer_stb),

	.we_i(we_o),
	.adr_i(adr_o[0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(timer_ack),
	.dat_o(timer_dat)
);

wb_i2s i2s_i (
	.clk_i(clk),
	.rst_i(rst),

	.cyc_i(cyc_o),
	.stb_i(i2s_stb),

	.we_i(we_o),
	.adr_i(adr_o[0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(i2s_ack),
	.dat_o(i2s_dat),

	.irq(i2s_irq),

	.wsel(i2s_wsel),
	.dout(i2s_dout),
	.bclk(i2s_bclk)
);

irqc #(
	.IW(4)
) irqc_i (
	.clk_i(clk),
	.rst_i(rst),

	.cyc_i(cyc_o),
	.stb_i(irqc_stb),

	.we_i(we_o),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(irqc_ack),
	.dat_o(irqc_dat),

	.irq_in({i2s_irq, !eth_int, systick_irq, uart_irq}),
	.irq_req(irq_req),
	.irq_vec(irq_vec),
	.irq_ack(irq_ack)
);

systick systick_i (
	.clk(clk),
	.rst(rst),
	.irq(systick_irq)
);

endmodule
