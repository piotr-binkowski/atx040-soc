module irqc (clk_i, rst_i, cyc_i, stb_i, we_i, dat_i, sel_i, ack_o, dat_o, irq_in, irq_req, irq_vec, irq_ack);

localparam DW = 32;
localparam IW = 32;
localparam COLS = DW/8;
localparam IRQ_BASE = 8'd64;

parameter CW = $clog2(IW);

input clk_i;
input rst_i;

input cyc_i;
input stb_i;

input we_i;

input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output [DW-1:0] dat_o;
output reg ack_o;

input [IW-1:0] irq_in;
output reg irq_req;
output [7:0] irq_vec;
input irq_ack;

reg [IW-1:0] irq_d   = {(IW){1'b0}};
reg [IW-1:0] irq_dd  = {(IW){1'b0}};
reg [IW-1:0] irq_i   = {(IW){1'b0}};
reg [IW-1:0] irq_ctl = {(DW){1'b0}};

reg [CW-1:0] irq_num = {(CW){1'b0}};

wire [IW-1:0] irq_masked = irq_i & irq_ctl;

assign irq_vec = IRQ_BASE + irq_num;
assign dat_o = irq_ctl;

always @(posedge clk_i)
	ack_o <= (ack_o) ? 1'b0 : stb_i;

integer i;

always @(posedge clk_i) begin
	if (rst_i) begin
		irq_i   <= {(IW){1'b0}};
		irq_d   <= {(IW){1'b0}};
		irq_dd  <= {(IW){1'b0}};
		irq_ctl <= {(IW){1'b0}};
		irq_num <= {(IW){1'b0}};
	end else begin
		irq_d  <= irq_in;
		irq_dd <= irq_d;

		if(we_i & ack_o & stb_i) begin
			irq_ctl <= dat_i;
		end

		for(i = 0; i < IW; i = i+1)
			if((irq_dd[i] == 1'b0) && (irq_d[i] == 1'b1))
				irq_i[i] <= 1'b1;

		for(i = 0; i < IW; i = i+1)
			if(irq_i[i])
				irq_num <= i;

		irq_req <= (irq_masked != {(IW){1'b0}}) ? 1'b1 : irq_req;

		if(irq_req & irq_ack) begin
			irq_i[irq_num] <= 1'b0;
			irq_req <= 1'b0;
		end
	end
end

endmodule
