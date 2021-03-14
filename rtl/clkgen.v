module clkgen (
	input  wire clk24_ref,
	output wire locked,
	/* CPU & SDRAM Clocks */
	output wire cpu_bclk,
	output wire cpu_pclk,
	output wire sys_clk,
	output wire sdram_clk,
	/* IO Clocks */
	output wire clk24,
	output wire clk25,
	output wire clk48
);

wire pll_cpu_fb;
wire pll_io_fb;

wire pll_cpu_locked;
wire pll_io_locked;

assign locked = pll_cpu_locked & pll_io_locked;

wire cpu_bclk_i;

BUFG bufg_bclk_i (
	.I(cpu_bclk_i),
	.O(cpu_bclk)
);

wire cpu_pclk_i;

BUFG bufg_pclk_i (
	.I(cpu_pclk_i),
	.O(cpu_pclk)
);

wire sys_clk_i;

BUFG bufg_sys_clk_i (
	.I(sys_clk_i),
	.O(sys_clk)
);

wire sdram_clk_i;

BUFG bufg_sdram_clk_i (
	.I(sdram_clk_i),
	.O(sdram_clk)
);

wire clk24_i;

BUFG bufg_clk24_i (
	.I(clk24_i),
	.O(clk24)
);

wire clk25_i;

BUFG bufg_clk25_i (
	.I(clk25_i),
	.O(clk25)
);

wire clk48_i;

BUFG bufg_clk48_i (
	.I(clk48_i),
	.O(clk48)
);

reg [3:0] rst = 4'b1111;

always @(posedge clk24_ref) begin
	rst <= {rst[2:0], 1'b0};
end

PLL_BASE #(
	.CLKIN_PERIOD(41.67),
	.CLKFBOUT_MULT(25),  // VCO    600MHz
	.CLKOUT0_DIVIDE(18), // BCLK   33MHz
	.CLKOUT1_DIVIDE(9),  // PCLK   66MHz
	.CLKOUT2_DIVIDE(6),  // SYSCLK 100Mhz
	.CLKOUT3_DIVIDE(6),  // SDRAM  100Mhz 90* PS
	.CLKOUT3_PHASE(90)
) pll_cpu (
	.CLKIN(clk24_ref),
	.CLKFBOUT(pll_cpu_fb),
	.CLKFBIN(pll_cpu_fb),
	.CLKOUT0(cpu_bclk_i),
	.CLKOUT1(cpu_pclk_i),
	.CLKOUT2(sys_clk_i),
	.CLKOUT3(sdram_clk_i),
	.LOCKED(pll_cpu_locked),
	.RST(rst[3])
);

PLL_BASE #(
	.CLKIN_PERIOD(41.67),
	.CLKFBOUT_MULT(40),  // VCO 960MHz
	.CLKOUT0_DIVIDE(40), // I2S 24MHz
	.CLKOUT1_DIVIDE(38), // VGA 25MHz
	.CLKOUT2_DIVIDE(20)  // USB 48MHz
) pll_io (
	.CLKIN(clk24_ref),
	.CLKFBOUT(pll_io_fb),
	.CLKFBIN(pll_io_fb),
	.CLKOUT0(clk24_i),
	.CLKOUT1(clk25_i),
	.CLKOUT2(clk48_i),
	.LOCKED(pll_io_locked),
	.RST(rst[3])
);

endmodule
