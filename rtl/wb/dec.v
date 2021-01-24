module wb_dec(
	clk_i, rst_i, stb_i, adr_i, ack_o, dat_o,
	rom_stb_o, rom_ack_i, rom_dat_i,
	ram_stb_o, ram_ack_i, ram_dat_i,
	uart_stb_o, uart_ack_i, uart_dat_i,
	sdram_stb_o, sdram_ack_i, sdram_dat_i,
);

localparam SDRAM_ADDR = 4'b0000;
localparam ROM_ADDR   = 4'b0001;
localparam RAM_ADDR   = 4'b0010;
localparam UART_ADDR  = 4'b0011;

localparam AW = 30;
localparam DW = 32;

input clk_i;
input rst_i;
input stb_i;

input [AW-1:0] adr_i;

output reg ack_o;
output reg [DW-1:0] dat_o;

output reg rom_stb_o;
input rom_ack_i;
input [DW-1:0] rom_dat_i;

output reg ram_stb_o;
input ram_ack_i;
input [DW-1:0] ram_dat_i;

output reg uart_stb_o;
input uart_ack_i;
input [DW-1:0] uart_dat_i;

output reg sdram_stb_o;
input sdram_ack_i;
input [DW-1:0] sdram_dat_i;

reg [1:0] acc_cnt = 2'b00;
wire force_rom = (acc_cnt < 2'b10); // First two accesses must go to ROM

always @(posedge clk_i)
	if (rst_i)
		acc_cnt <= 2'b00;
	else if (ack_o && (acc_cnt < 2'b10))
		acc_cnt <= acc_cnt + 1'b1;

always @(*) begin
	ack_o       = 0;
	dat_o       = 0;
	rom_stb_o   = 0;
	ram_stb_o   = 0;
	uart_stb_o  = 0;
	sdram_stb_o = 0;
	if (force_rom) begin
		ack_o = rom_ack_i;
		dat_o = rom_dat_i;
		rom_stb_o = stb_i;
	end else begin
		case(adr_i[AW-1:AW-4])
			SDRAM_ADDR: begin
				ack_o = sdram_ack_i;
				dat_o = sdram_dat_i;
				sdram_stb_o = stb_i;
			end
			ROM_ADDR: begin
				ack_o = rom_ack_i;
				dat_o = rom_dat_i;
				rom_stb_o = stb_i;
			end
			RAM_ADDR: begin
				ack_o = ram_ack_i;
				dat_o = ram_dat_i;
				ram_stb_o = stb_i;
			end
			UART_ADDR: begin
				ack_o = uart_ack_i;
				dat_o = uart_dat_i;
				uart_stb_o = stb_i;
			end
		endcase
	end
end

endmodule
