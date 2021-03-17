module clkgen (
	input  wire clk24_ref,
	output wire locked,
	output wire cpu_bclk,
	output wire cpu_pclk,
	output wire sys_clk,
	output wire sdram_clk,
	output wire vga_clk
);

wire pll_fb;

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

wire vga_clk_i;

BUFG bufg_vga_clk_i (
	.I(vga_clk_i),
	.O(vga_clk)
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
	.CLKOUT2_DIVIDE(6),  // SYSCLK 100MHz
	.CLKOUT3_DIVIDE(6),  // SDRAM  100MHz 90* PS
	.CLKOUT3_PHASE(90),
	.CLKOUT4_DIVIDE(25)  // VGA    25MHz
) pll_cpu (
	.CLKIN(clk24_ref),
	.CLKFBOUT(pll_fb),
	.CLKFBIN(pll_fb),
	.CLKOUT0(cpu_bclk_i),
	.CLKOUT1(cpu_pclk_i),
	.CLKOUT2(sys_clk_i),
	.CLKOUT3(sdram_clk_i),
	.CLKOUT4(vga_clk_i),
	.LOCKED(locked),
	.RST(rst[3])
);

endmodule
