module vga_core(clk, vsync, hsync, de);

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
