module vga_core(
	clk, rst,

	cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o,

	req_valid, req_ready,
	req_len, req_mask, req_addr, req_we, req_wrap,

	write_valid, write_data,

	read_valid, read_data, read_ack,

	pix_clk, pix_out, hsync, vsync
);

parameter LW = 8;

localparam DW   = 32;
localparam AW   = 32;
localparam MW   = 4;
localparam PIXW = 16;

input      clk;
input      rst;

/* Configuration bus */

input      cyc_i;
input      stb_i;
input      adr_i;
input      we_i;

input      [DW-1:0] dat_i;
input      [MW-1:0] sel_i;

output reg ack_o;
output     [DW-1:0] dat_o;

/* SDRAM bus */

output     req_valid;
input      req_ready;

output     [LW-1:0] req_len;
output     [MW-1:0] req_mask;
output     [AW-1:0] req_addr;
output     req_we;
output     req_wrap;

output     write_valid;
output     [DW-1:0] write_data;

input      read_valid;
input      [DW-1:0] read_data;
output     read_ack;

/* Pixel bus */

output reg [17:0] pix_out;
output reg hsync;
output reg vsync;
output     pix_clk;

reg  en = 1'b0;
reg  [DW-1:0] base_addr = {(DW){1'b0}};

always @(posedge clk)
	if(ack_o)
		ack_o <= 1'b0;
	else
		ack_o <= stb_i;

always @(posedge clk) begin
	if(rst) begin
		en <= 1'b0;
		base_addr <= {(DW){1'b0}};
	end else if(ack_o && stb_i && we_i) begin
		if(adr_i)
			base_addr <= dat_i;
		else
			en <= dat_i[0];
	end
end

assign dat_o = (adr_i) ? base_addr : {31'd0, en};

wire vga_sync;
wire dma_data_valid, dma_data_ready, pix_data_valid, pix_data_ready;
wire [DW-1:0] dma_data;
wire [PIXW-1:0] pix_data;

req_dma #(
	.PIXW(PIXW),
	.LW(LW)
) req_dma_i (
	.clk(clk),
	.rst(rst),

	.base_addr(base_addr),

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
	.read_data(read_data),
	.read_ack(read_ack),

	.dout_valid(dma_data_valid),
	.dout_ready(dma_data_ready),
	.dout(dma_data),
	.sync(vga_sync & en)
);

stream_downsize #(
	.DIN_DW(DW),
	.DOUT_DW(PIXW)
) downsize_i (
	.clk(clk),
	.rst(rst),
	.din_valid(dma_data_valid),
	.din_ready(dma_data_ready),
	.din(dma_data),
	.dout_valid(pix_data_valid),
	.dout_ready(pix_data_ready),
	.dout(pix_data)
);

wire vsync_i, hsync_i, de_i;

always @(posedge clk) begin
	if(PIXW == 8)
		pix_out <= (de_i) ? {pix_data[7:5], 3'd0, pix_data[4:2], 3'd0, pix_data[1:0], 4'd0} : {18'd0};
	else if(PIXW == 16)
		pix_out <= (de_i) ? {pix_data[15:11], 1'b0, pix_data[10:5], pix_data[4:0], 1'b0} : {18'd0};

	hsync <= hsync_i;
	vsync <= vsync_i;
end

vga_timing vga_i (
	.clk(clk),
	.vsync(vsync_i),
	.hsync(hsync_i),
	.de(de_i),
	.ack(pix_data_ready),
	.sync(vga_sync),
	.vclk(pix_clk)
);

endmodule

/* VGA timing generator */

module vga_timing(clk, vsync, hsync, de, ack, sync, vclk);

parameter DIV = 4;
parameter HVIS = 640;
parameter HFP  = 16;
parameter HSP  = 96;
parameter HBP  = 48;

parameter VVIS = 400;
parameter VFP  = 12;
parameter VSP  = 2;
parameter VBP  = 35;

parameter HMAX = HVIS + HFP + HSP + HBP - 1;
parameter VMAX = VVIS + VFP + VSP + VBP - 1;

parameter HW = $clog2(HMAX);
parameter VW = $clog2(VMAX);

parameter CW = $clog2(DIV);

input  clk;
output vsync;
output hsync;
output de;
output ack;
output sync;
output reg vclk;

reg [HW-1:0] hcnt = {(HW){1'b0}};
reg [VW-1:0] vcnt = {(VW){1'b0}};
reg [CW-1:0] ccnt = {(CW){1'b0}};
reg strobe = 1'b0;

wire de_x = (hcnt < HVIS);
wire de_y = (vcnt < VVIS);

assign de = de_x && de_y;

assign hsync = (hcnt >= (HVIS + HFP)) && (hcnt < (HVIS + HFP + HSP));
assign vsync = (vcnt >= (VVIS + VFP)) && (vcnt < (VVIS + VFP + VSP));

assign ack = de & strobe;

assign sync = (vcnt == (VVIS + VFP)) && (hcnt == (HVIS + HFP)) && strobe;

always @(posedge clk) begin
	if(ccnt == (DIV-1)) begin
		strobe <= 1'b1;
		ccnt <= {(CW){1'b0}};
	end else begin
		strobe <= 1'b0;
		ccnt <= ccnt + 1'b1;
	end
end

always @(posedge clk) begin
	if(ccnt == (DIV/2 - 1))
		vclk <= 1'b1;
	else if(ccnt == (DIV-1))
		vclk <= 1'b0;
end

always @(posedge clk)
	if(strobe) begin
		if(hcnt == HMAX)
			hcnt <= 0;
		else
			hcnt <= hcnt + 1'b1;
	end

always @(posedge clk)
	if(strobe) begin
		if(hcnt == HMAX)
			if(vcnt == VMAX)
				vcnt <= 0;
			else
				vcnt <= vcnt + 1'b1;
	end

endmodule
