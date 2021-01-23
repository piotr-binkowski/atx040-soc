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
	input  wire ps2_dat,
	input  wire ps2_clk
);

wire clk24_buf;

wire cpu_bclk_i;
wire cpu_pclk_i;
wire sys_clk;
wire sdram_clk_i;

wire locked;

IBUFG clk24_ibuf (
	.I(clk24),
	.O(clk24_buf)
);

clkgen clkgen_i (
	.clk24_ref(clk24_buf),
	.locked(locked),
	.cpu_bclk(cpu_bclk_i),
	.cpu_pclk(cpu_pclk_i),
	.sys_clk(sys_clk),
	.sdram_clk(sdram_clk_i)
);

ODDR2 oddr_cpu_bclk (
	.C0(cpu_bclk_i),
	.C1(~cpu_bclk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.Q(cpu_bclk)
);

ODDR2 oddr_cpu_pclk (
	.C0(cpu_pclk_i),
	.C1(~cpu_pclk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.Q(cpu_pclk)
);

ODDR2 oddr_sdram_clk (
	.C0(sdram_clk_i),
	.C1(~sdram_clk_i),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.Q(sdram_clk)
);

wire [31:0] cpu_ad_i;
wire [31:0] cpu_ad_o;
wire cpu_ad_t;

genvar i;

generate
	for(i = 0; i < 32; i = i + 1) begin : iobuf_gen
		IOBUF iobuf_cpu_ad (
			.IO(cpu_ad[i]),
			.O(cpu_ad_o[i]),
			.I(cpu_ad_i[i]),
			.T(cpu_ad_t)
		);
	end
endgenerate

wire cyc_o;
wire stb_o;
wire rom_stb;
wire uart_stb;

wire ack_i;
wire rom_ack;
wire uart_ack;

wire we_o;
wire [3:0] sel_o;

wire [29:0] adr_o;

wire [31:0] dat_o;
wire [31:0] dat_i;

assign rom_stb  = stb_o && (adr_o[29] == 1'b0);
assign uart_stb = stb_o && (adr_o[29] == 1'b1);

assign ack_i = rom_ack | uart_ack;

cpuif cpuif_i (
	.clk(sys_clk),
	.bclk(cpu_bclk_i),

	.reset(1'b0),

	.cpu_ad_i(cpu_ad_i),
	.cpu_ad_o(cpu_ad_o),
	.cpu_ad_t(cpu_ad_t),

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

	.wb_cyc_o(cyc_o),
	.wb_stb_o(stb_o),
	.wb_ack_i(ack_i),
	.wb_we_o(we_o),
	.wb_sel_o(sel_o),
	.wb_adr_o(adr_o),
	.wb_dat_o(dat_o),
	.wb_dat_i(dat_i)
);

wb_rom #(
	.INIT("rom.mem")
) rom_i (
	.clk(sys_clk),
	.cyc_i(cyc_o),
	.stb_i(rom_stb),
	.ack_o(rom_ack),
	.dat_o(dat_i),
	.dat_i(dat_o),
	.we_i(1'b0),
	.adr_i(adr_o)
);

wb_uart uart_i (
	.clk(sys_clk),
	.txd(uart_txd),
	.cyc_i(cyc_o),
	.stb_i(uart_stb),
	.ack_o(uart_ack),
	.dat_i(dat_o),
	.we_o(we_o)
);

assign sdram_cke = 0;
assign sdram_dm  = 0;
assign sdram_a   = 0;
assign sdram_ba  = 0;
assign sdram_cas = 1;
assign sdram_ras = 1;
assign sdram_cs  = 1;
assign sdram_we  = 1;

assign sd_cs   = 1;
assign sd_mosi = 0;
assign sd_sck  = 0;

assign eth_cs   = 1;
assign eth_mosi = 0;
assign eth_sck  = 0;
assign eth_rst  = 0;

assign i2s_wsel = 0;
assign i2s_dout = 0;
assign i2s_bclk = 0;

endmodule
