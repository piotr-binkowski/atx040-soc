module vga_data_sync(clk, pclk, vsync_i, hsync_i, de_i, dat_i, dat_ack, vsync_o, hsync_o, dat_o);

parameter DW = 18;

input clk;
input pclk;

input vsync_i;
input hsync_i;
input de_i;

input [DW-1:0] dat_i;

output reg dat_ack = 1'b0;
output reg vsync_o = 1'b0;
output reg hsync_o = 1'b0;
output reg [DW-1:0] dat_o;

/* Phase detect */

reg pclk_phase = 0;
reg clk_phase  = 0;

reg [1:0] phase = 0;

always @(posedge pclk)
	pclk_phase <= ~pclk_phase;

always @(posedge clk)
	clk_phase <= pclk_phase;

always @(posedge clk)
	if(clk_phase ^ pclk_phase)
		phase <= 2'd2;
	else
		phase <= phase + 1'b1;

always @(posedge clk) begin
	dat_ack <= 1'b0;
	if(phase == 0) begin
		hsync_o <= hsync_i;
		vsync_o <= vsync_i;
		if(de_i) begin
			dat_o   <= dat_i;
			dat_ack <= 1'b1;
		end else begin
			dat_o   <= {(DW){1'b0}};
		end
	end
end

endmodule

module vga_timing(clk, vsync, hsync, de);

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

input  clk;
output vsync;
output hsync;
output de;

reg [HW-1:0] hcnt = {(HW){1'b0}};
reg [VW-1:0] vcnt = {(VW){1'b0}};

wire de_x = (hcnt < HVIS);
wire de_y = (vcnt < VVIS);

assign de = de_x && de_y;

assign hsync = (hcnt >= (HVIS + HFP)) && (hcnt < (HVIS + HFP + HSP));
assign vsync = (vcnt >= (VVIS + VFP)) && (vcnt < (VVIS + VFP + VSP));

always @(posedge clk)
	if(hcnt == HMAX)
		hcnt <= 0;
	else
		hcnt <= hcnt + 1'b1;

always @(posedge clk)
	if(hcnt == HMAX)
		if(vcnt == VMAX)
			vcnt <= 0;
		else
			vcnt <= vcnt + 1'b1;

endmodule
