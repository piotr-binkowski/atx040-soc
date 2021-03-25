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

wire cpu_bclk_i, cpu_pclk_i, sys_clk, sdram_clk_i;

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

wire reset_ext;
wire sdram_init_done;

assign usb0_pu = 1'b1;
assign usb1_pu = 1'b1;

reset_gen reset_gen_i (
	.rstn(usb0_p),
	.clk(sys_clk),
	.reset(reset_ext)
);

localparam LW = 8;
localparam MW = 4;
localparam DW = 32;
localparam AW = 32;

wire sdram_rst_o = (!cpu_rsto) | reset_ext;
wire rst_o = sdram_rst_o | (!sdram_init_done);

wire cpu_req_valid, cpu_sdram_req_valid, dma_req_valid, sdram_req_valid, wb_req_valid;
wire cpu_req_ready, cpu_sdram_req_ready, dma_req_ready, sdram_req_ready, wb_req_ready;

wire cpu_req_we, dma_req_we, sdram_req_we;
wire cpu_req_wrap, dma_req_wrap, sdram_req_wrap;
wire [LW-1:0] cpu_req_len, dma_req_len, sdram_req_len;
wire [MW-1:0] cpu_req_mask, dma_req_mask, sdram_req_mask;
wire [AW-1:0] cpu_req_addr, dma_req_addr, sdram_req_addr;

wire cpu_write_valid, cpu_sdram_write_valid, dma_write_valid, sdram_write_valid, wb_write_valid;
wire [DW-1:0] cpu_write_data, dma_write_data, sdram_write_data;

wire cpu_read_valid, cpu_sdram_read_valid, dma_read_valid, sdram_read_valid, wb_read_valid;
wire [DW-1:0] cpu_read_data, cpu_sdram_read_data, dma_read_data, sdram_read_data, wb_read_data;
wire cpu_read_ack, cpu_sdram_read_ack, dma_read_ack, sdram_read_ack, wb_read_ack;

wire irq_req;
wire [7:0] irq_vec;
wire irq_ack;

cpuif #(
	.LW(LW)
) cpuif_i (
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
	.req_wrap(cpu_req_wrap),

	.write_valid(cpu_write_valid),
	.write_data(cpu_write_data),

	.read_valid(cpu_read_valid),
	.read_data(cpu_read_data),
	.read_ack(cpu_read_ack),

	.irq_req(irq_req),
	.irq_vec(irq_vec),
	.irq_ack(irq_ack)
);

localparam DUMMY_SLAVES = 14;

wire [DUMMY_SLAVES-1:0] slv_req_valid, slv_write_valid, slv_read_ack;

req_decoder #(
	.SLAVES(16)
) req_decoder_i (
	.req_valid(cpu_req_valid),
	.req_ready(cpu_req_ready),
	.req_addr(cpu_req_addr[(AW-1)-:4]),

	.write_valid(cpu_write_valid),

	.read_ack(cpu_read_ack),
	.read_data(cpu_read_data),
	.read_valid(cpu_read_valid),

	.slv_req_valid({wb_req_valid, slv_req_valid, cpu_sdram_req_valid}),
	.slv_req_ready({wb_req_ready, {(DUMMY_SLAVES){1'b0}}, cpu_sdram_req_ready}),

	.slv_write_valid({wb_write_valid, slv_write_valid, cpu_sdram_write_valid}),

	.slv_read_ack({wb_read_ack, slv_read_ack, cpu_sdram_read_ack}),
	.slv_read_data({wb_read_data, {(DW*DUMMY_SLAVES){1'b0}}, cpu_sdram_read_data}),
	.slv_read_valid({wb_read_valid, {(DUMMY_SLAVES){1'b0}}, cpu_sdram_read_valid})
);

req_arbiter #(
	.MASTERS(2),
	.LW(LW)
) req_arbiter_i (
	.clk(sys_clk),
	.rst(rst_o),

	.m_req_valid({dma_req_valid, cpu_sdram_req_valid}),
	.m_req_ready({dma_req_ready, cpu_sdram_req_ready}),
	.m_req_len({dma_req_len, cpu_req_len}),
	.m_req_mask({dma_req_mask, cpu_req_mask}),
	.m_req_addr({dma_req_addr, cpu_req_addr}),
	.m_req_we({dma_req_we, cpu_req_we}),
	.m_req_wrap({dma_req_wrap, cpu_req_wrap}),

	.m_write_valid({dma_write_valid, cpu_sdram_write_valid}),
	.m_write_data({dma_write_data, cpu_write_data}),

	.m_read_valid({dma_read_valid, cpu_sdram_read_valid}),
	.m_read_data({dma_read_data, cpu_sdram_read_data}),
	.m_read_ack({dma_read_ack, cpu_sdram_read_ack}),

	.req_ready(sdram_req_ready),
	.req_valid(sdram_req_valid),
	.req_len(sdram_req_len),
	.req_mask(sdram_req_mask),
	.req_addr(sdram_req_addr),
	.req_we(sdram_req_we),
	.req_wrap(sdram_req_wrap),

	.write_valid(sdram_write_valid),
	.write_data(sdram_write_data),

	.read_valid(sdram_read_valid),
	.read_data(sdram_read_data),
	.read_ack(sdram_read_ack)
);

peripherals #(
	.LW(LW)
) periph_i (
	.clk(sys_clk),
	.rst(rst_o),

	.req_valid(wb_req_valid),
	.req_ready(wb_req_ready),
	.req_len(cpu_req_len),
	.req_mask(cpu_req_mask),
	.req_addr(cpu_req_addr),
	.req_we(cpu_req_we),
	.req_wrap(cpu_req_wrap),

	.write_data(cpu_write_data),
	.write_valid(wb_write_valid),

	.read_ack(wb_read_ack),
	.read_data(wb_read_data),
	.read_valid(wb_read_valid),

	.vga_req_valid(dma_req_valid),
	.vga_req_ready(dma_req_ready),
	.vga_req_len(dma_req_len),
	.vga_req_mask(dma_req_mask),
	.vga_req_addr(dma_req_addr),
	.vga_req_we(dma_req_we),
	.vga_req_wrap(dma_req_wrap),

	.vga_write_valid(dma_write_valid),
	.vga_write_data(dma_write_data),

	.vga_read_valid(dma_read_valid),
	.vga_read_data(dma_read_data),
	.vga_read_ack(dma_read_ack),

	.vga_pix({vga_r, vga_g, vga_b}),
	.vga_clk(vga_clk),
	.vga_hsync(vga_hsync),
	.vga_vsync(vga_vsync),

	.uart_txd(uart_txd),
	.uart_rxd(uart_rxd),

	.eth_cs(eth_cs),
	.eth_int(eth_int),
	.eth_sck(eth_sck),
	.eth_miso(eth_miso),
	.eth_mosi(eth_mosi),

	.flash_cs(flash_cs),
	.flash_sck(flash_sck),
	.flash_miso(flash_miso),
	.flash_mosi(flash_mosi),

	.sd_cs(sd_cs),
	.sd_sck(sd_sck),
	.sd_miso(sd_miso),
	.sd_mosi(sd_mosi),

	.i2s_wsel(i2s_wsel),
	.i2s_dout(i2s_dout),
	.i2s_bclk(i2s_bclk),

	.irq_req(irq_req),
	.irq_vec(irq_vec),
	.irq_ack(irq_ack)
);

req_sdram #(
	.LW(LW)
) sdram_i (
	.clk(sys_clk),
	.rst(sdram_rst_o),

	.init_done(sdram_init_done),

	.req_valid(sdram_req_valid),
	.req_ready(sdram_req_ready),
	.req_addr(sdram_req_addr),
	.req_mask(sdram_req_mask),
	.req_len(sdram_req_len),
	.req_we(sdram_req_we),
	.req_wrap(sdram_req_wrap),

	.write_valid(sdram_write_valid),
	.write_data(sdram_write_data),

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

assign eth_rst  = !rst_o;

endmodule
