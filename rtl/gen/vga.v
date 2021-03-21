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
