module wb_rom (
	input  wire clk,
	
	input  wire cyc_i,
	input  wire stb_i,
	output wire ack_o,
	output wire [31:0] dat_o,
	input  wire [31:0] dat_i,
	input  wire [9:0] adr_i,
	input  wire we_o
);

reg [31:0] mem [0:1023];

initial
	$readmemh("rom.mem", mem);

assign ack_o = stb_i;

reg [31:0] dout;

assign dat_o = dout;

always @(adr_i)
	dout <= mem[adr_i];

always @(posedge clk)
	if(stb_i == 1'b1 && we_o == 1'b1)
		mem[adr_i] <= dat_i;

endmodule
