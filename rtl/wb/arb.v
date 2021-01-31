module wb_arb(
	clk_i, rst_i,
	stb_i, adr_i, ack_o, dat_o,
	slv_stb_o, slv_ack_i, slv_dat_i,
);

parameter  SLAVES = 16;
parameter  SW = $clog2(SLAVES);
parameter  AW = 28;

localparam DW = 32;

input clk_i;
input rst_i;
input stb_i;

input [AW-1:0] adr_i;

output reg ack_o;
output reg [DW-1:0] dat_o;

output reg [SLAVES-1:0] slv_stb_o;
input [SLAVES-1:0] slv_ack_i;
input [SLAVES*DW-1:0] slv_dat_i;

integer i;

always @(*) begin
	ack_o       = 0;
	dat_o       = 0;
	slv_stb_o   = 0;
	for (i = 0; i < SLAVES; i = i+1) begin
		if (adr_i[AW-1:AW-SW] == i) begin
			ack_o        = slv_ack_i[i];
			dat_o        = slv_dat_i[i*DW+:DW];
			slv_stb_o[i] = stb_i;
		end
	end
end

endmodule
