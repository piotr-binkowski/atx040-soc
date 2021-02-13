module wb_tim(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o);

localparam AW   = 1;
localparam DW   = 32;
localparam COLS = DW/8;

input clk_i;
input rst_i;

input cyc_i;
input stb_i;

input [AW-1:0] adr_i;
input we_i;

input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output [DW-1:0] dat_o;
output reg ack_o;

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

reg [63:0] counter = 64'd0;
reg [63:0] counter_o;

always @(posedge clk_i) begin
	if(stb_i && !ack_o)
		counter_o <= counter;

	if(rst_i)
		counter <= 64'd0;
	else
		counter <= counter + 1'b1;
end

assign dat_o = (adr_i[0]) ? counter_o[63:32] : counter_o[31:0];

endmodule
