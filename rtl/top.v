module top(
	input  wire clk24,
	/* UART */
	output wire uart_txd,
	input  wire uart_rxd,
	/* MC68040 */
	output wire cpu_bclk,
	output wire cpu_pclk,

	inout  wire [31:0] cpu_ad,
	output wire cpu_dir,
	output wire cpu_oe,

	input  wire [1:0] cpu_siz,
	input  wire [1:0] cpu_tt,
	input  wire cpu_rsto,
	input  wire cpu_tip,
	input  wire cpu_ts,
	input  wire cpu_rw,

	output wire cpu_cdis,
	output wire cpu_rsti,
	output wire cpu_irq,
	output wire cpu_ta,
	/* SDRAM */
	output wire sdram_clk,
	output wire sdram_cke,

	inout  wire [15:0] sdram_d,
	output wire [1:0] sdram_dm,

	output wire [12:0] sdram_a,
	output wire [1:0] sdram_ba,
	output wire sdram_cas,
	output wire sdram_ras,
	output wire sdram_cs,
	output wire sdram_we,
	/* Flash */
	input  wire flash_miso,
	output wire flash_mosi,
	output wire flash_sck,
	output wire flash_cs,
	/* SD Card */
	input  wire sd_miso,
	output wire sd_mosi,
	output wire sd_sck,
	output wire sd_cs,
	/* Ethernet */
	input  wire eth_miso,
	output wire eth_mosi,
	output wire eth_sck,
	output wire eth_cs,

	input  wire eth_int,
	output wire eth_rst,
	/* Audio */
	output wire i2s_wsel,
	output wire i2s_dout,
	output wire i2s_bclk,
	/* PS2 */
	//input  wire ps2_dat,
	//input  wire ps2_clk,
	/* USB */
	//input  wire usb0_m,
	input  wire usb0_p,
	output wire usb0_pu,
	//input  wire usb1_m,
	input  wire usb1_p,
	output wire usb1_pu,
	/* VGA */
	output wire vga_clk,
	output wire vga_vsync,
	output wire vga_hsync,

	output wire [5:0] vga_b,
	output wire [5:0] vga_g,
	output wire [5:0] vga_r
);

wire clk24_buf;

wire cpu_bclk_i;
wire cpu_pclk_i;
wire sys_clk;
wire sdram_clk_i;
wire vga_clk_i;

IBUFG clk24_ibuf (
	.I(clk24),
	.O(clk24_buf)
);

clkgen clkgen_i (
	.clk24_ref(clk24_buf),
	.cpu_bclk(cpu_bclk_i),
	.cpu_pclk(cpu_pclk_i),
	.sys_clk(sys_clk),
	.sdram_clk(sdram_clk_i),
	.vga_clk(vga_clk_i),
	.locked()
);

ODDR2 oddr_cpu_bclk (
	.C0(cpu_bclk_i),
	.C1(~cpu_bclk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0),
	.Q(cpu_bclk)
);

ODDR2 oddr_cpu_pclk (
	.C0(cpu_pclk_i),
	.C1(~cpu_pclk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0),
	.Q(cpu_pclk)
);

ODDR2 oddr_sdram_clk (
	.C0(sdram_clk_i),
	.C1(~sdram_clk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0),
	.Q(sdram_clk)
);

ODDR2 oddr_vga_clk (
	.C0(vga_clk_i),
	.C1(~vga_clk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0),
	.Q(vga_clk)
);

wire reset_ext;
wire sdram_init_done;

assign usb0_pu = 1'b1;
assign usb1_pu = 1'b1;

reset_gen reset_gen_i (
	.rstn(usb0_p),
	.clk(sys_clk),
	.reset(reset_ext)
);

wire sdram_rst_o = (!cpu_rsto) | reset_ext;
wire rst_o = sdram_rst_o | (!sdram_init_done);

wire cpu_req_valid;
wire cpu_req_ready;

wire cpu_req_we;
wire [2:0] cpu_req_len;
wire [3:0] cpu_req_mask;
wire [31:0] cpu_req_addr;

wire cpu_write_valid;
wire [31:0] cpu_write_data;

wire cpu_read_valid;
wire [31:0] cpu_read_data;
wire cpu_read_ack;

wire irq_req;
wire [7:0] irq_vec;
wire irq_ack;
wire [31:0] irq;

cpuif cpuif_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.bclk(cpu_bclk_i),

	.cdis_ext(!usb1_pu),

	.cpu_ad(cpu_ad),
	.cpu_dir(cpu_dir),
	.cpu_oe(cpu_oe),

	.cpu_siz(cpu_siz),
	.cpu_tt(cpu_tt),
	.cpu_rsto(cpu_rsto),
	.cpu_tip(cpu_tip),
	.cpu_ts(cpu_ts),
	.cpu_rw(cpu_rw),

	.cpu_cdis(cpu_cdis),
	.cpu_rsti(cpu_rsti),
	.cpu_irq(cpu_irq),
	.cpu_ta(cpu_ta),

	.req_valid(cpu_req_valid),
	.req_ready(cpu_req_ready),
	.req_mask(cpu_req_mask),
	.req_addr(cpu_req_addr),
	.req_len(cpu_req_len),
	.req_we(cpu_req_we),

	.write_valid(cpu_write_valid),
	.write_data(cpu_write_data),

	.read_valid(cpu_read_valid),
	.read_data(cpu_read_data),
	.read_ack(cpu_read_ack),

	.irq_req(irq_req),
	.irq_vec(irq_vec),
	.irq_ack(irq_ack)
);

wire sdram_req_valid;
wire sdram_req_ready;

wire sdram_write_valid;

wire sdram_read_ack;
wire sdram_read_valid;
wire [31:0] sdram_read_data;

wire wb_req_valid;
wire wb_req_ready;

wire wb_write_valid;

wire wb_read_ack;
wire wb_read_valid;
wire [31:0] wb_read_data;

req_mux req_mux_i (
	.cpu_req_len(cpu_req_len),
	.cpu_req_addr(cpu_req_addr[31:30]),
	.cpu_req_valid(cpu_req_valid),
	.cpu_req_ready(cpu_req_ready),

	.cpu_write_valid(cpu_write_valid),

	.cpu_read_ack(cpu_read_ack),
	.cpu_read_data(cpu_read_data),
	.cpu_read_valid(cpu_read_valid),

	.sdram_req_ready(sdram_req_ready),
	.sdram_req_valid(sdram_req_valid),

	.sdram_write_valid(sdram_write_valid),

	.sdram_read_ack(sdram_read_ack),
	.sdram_read_data(sdram_read_data),
	.sdram_read_valid(sdram_read_valid),

	.wb_req_ready(wb_req_ready),
	.wb_req_valid(wb_req_valid),

	.wb_write_valid(wb_write_valid),

	.wb_read_ack(wb_read_ack),
	.wb_read_data(wb_read_data),
	.wb_read_valid(wb_read_valid)
);

wire cyc_o;
wire stb_o;
wire ack_i;
wire we_o;
wire [3:0] sel_o;
wire [29:0] adr_o;
wire [31:0] dat_o;
wire [31:0] dat_i;

req_wb_bridge bridge_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.req_valid(wb_req_valid),
	.req_ready(wb_req_ready),
	.req_len(cpu_req_len),
	.req_mask(cpu_req_mask),
	.req_addr(cpu_req_addr),
	.req_we(cpu_req_we),

	.write_valid(wb_write_valid),
	.write_data(cpu_write_data),

	.read_valid(wb_read_valid),
	.read_ack(wb_read_ack),
	.read_data(wb_read_data),

	.wb_cyc_o(cyc_o),
	.wb_stb_o(stb_o),
	.wb_ack_i(ack_i),
	.wb_we_o(we_o),
	.wb_sel_o(sel_o),
	.wb_adr_o(adr_o),
	.wb_dat_o(dat_o),
	.wb_dat_i(dat_i)
);

wire        rom_stb, ram_stb, periph_stb;
wire        rom_ack, ram_ack, periph_ack;
wire [31:0] rom_dat, ram_dat, periph_dat;

wb_dec dec_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),
	.stb_i(stb_o),
	.adr_i(adr_o),
	.ack_o(ack_i),
	.dat_o(dat_i),

	.rom_stb_o(rom_stb),
	.rom_ack_i(rom_ack),
	.rom_dat_i(rom_dat),

	.ram_stb_o(ram_stb),
	.ram_ack_i(ram_ack),
	.ram_dat_i(ram_dat),

	.periph_stb_o(periph_stb),
	.periph_ack_i(periph_ack),
	.periph_dat_i(periph_dat),

	.sdram_stb_o(),
	.sdram_ack_i(1'b0),
	.sdram_dat_i(32'd0)
);

wire        uart_stb, flash_stb, timer_stb, sd_stb, eth_stb, irqc_stb, i2s_stb;
wire        uart_ack, flash_ack, timer_ack, sd_ack, eth_ack, irqc_ack, i2s_ack;
wire [31:0] uart_dat, flash_dat, timer_dat, sd_dat, eth_dat, irqc_dat, i2s_dat;

wb_arb #(
	.SLAVES(16)
) arb_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),
	.stb_i(periph_stb),
	.adr_i(adr_o[27:24]),
	.ack_o(periph_ack),
	.dat_o(periph_dat),
	.slv_stb_o({i2s_stb, irqc_stb, eth_stb, sd_stb, timer_stb, flash_stb, uart_stb}),
	.slv_ack_i({i2s_ack, irqc_ack, eth_ack, sd_ack, timer_ack, flash_ack, uart_ack}),
	.slv_dat_i({i2s_dat, irqc_dat, eth_dat, sd_dat, timer_dat, flash_dat, uart_dat})
);

wb_mem #(
	.ROM("TRUE"),
	.SIZE(1024),
	.INIT("rom.mem")
) rom_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.cyc_i(cyc_o),
	.stb_i(rom_stb),

	.we_i(we_o),
	.adr_i(adr_o[9:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(rom_ack),
	.dat_o(rom_dat)
);

wb_mem #(
	.SIZE(1024)
) ram_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.cyc_i(cyc_o),
	.stb_i(ram_stb),

	.we_i(we_o),
	.adr_i(adr_o[9:0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(ram_ack),
	.dat_o(ram_dat)
);

wire uart_irq;

wb_uart uart_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

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
	.clk_i(sys_clk),
	.rst_i(rst_o),
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
	.clk_i(sys_clk),
	.rst_i(rst_o),
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
	.clk_i(sys_clk),
	.rst_i(rst_o),
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
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.cyc_i(cyc_o),
	.stb_i(timer_stb),

	.we_i(we_o),
	.adr_i(adr_o[0]),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(timer_ack),
	.dat_o(timer_dat)
);

wire i2s_irq;

wb_i2s i2s_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

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

irqc irqc_i (
	.clk_i(sys_clk),
	.rst_i(rst_o),

	.cyc_i(cyc_o),
	.stb_i(irqc_stb),

	.we_i(we_o),

	.sel_i(sel_o),
	.dat_i(dat_o),

	.ack_o(irqc_ack),
	.dat_o(irqc_dat),

	.irq_in(irq),
	.irq_req(irq_req),
	.irq_vec(irq_vec),
	.irq_ack(irq_ack)
);

wire vga_de;

vga_timing vga_i (
	.clk(vga_clk_i),
	.vsync(vga_vsync),
	.hsync(vga_hsync),
	.de(vga_de)
);

assign vga_r = (vga_de) ? 6'h3F : 6'h00;
assign vga_g = (vga_de) ? 6'h3F : 6'h00;
assign vga_b = (vga_de) ? 6'h3F : 6'h00;

req_sdram sdram_i (
	.clk(sys_clk),
	.rst(sdram_rst_o),

	.init_done(sdram_init_done),

	.req_valid(sdram_req_valid),
	.req_ready(sdram_req_ready),
	.req_addr(cpu_req_addr),
	.req_mask(cpu_req_mask),
	.req_len(cpu_req_len),
	.req_we(cpu_req_we),

	.write_valid(sdram_write_valid),
	.write_data(cpu_write_data),

	.read_valid(sdram_read_valid),
	.read_data(sdram_read_data),
	.read_ack(sdram_read_ack),

	.cke(sdram_cke),
	.cs(sdram_cs),
	.ras(sdram_ras),
	.cas(sdram_cas),
	.we(sdram_we),
	.d(sdram_d),
	.dm(sdram_dm),
	.a(sdram_a),
	.ba(sdram_ba)
);

wire systick_irq;

systick systick_i (
	.clk(sys_clk),
	.rst(rst_o),
	.irq(systick_irq)
);

assign eth_rst  = !rst_o;

assign irq = {28'd0, i2s_irq, !eth_int, systick_irq, uart_irq};

endmodule
