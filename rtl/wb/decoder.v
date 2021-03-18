module wb_decoder(
	stb_i, adr_i, ack_o, dat_o,
	slv_stb_o, slv_ack_i, slv_dat_i
);

parameter  SLAVES = 16;
parameter  SW = $clog2(SLAVES);

localparam DW = 32;

input stb_i;
input [SW-1:0] adr_i;

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
		if (adr_i == i) begin
			ack_o        = slv_ack_i[i];
			dat_o        = slv_dat_i[i*DW+:DW];
			slv_stb_o[i] = stb_i;
		end
	end
end

endmodule
