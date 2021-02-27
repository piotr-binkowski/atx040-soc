module req_mux(
	input clk,
	input rst,

	input cpu_req_we,
	input cpu_req_valid,
	output cpu_req_ready,
	input [2:0] cpu_req_len,
	input [31:0] cpu_req_addr,

	input cpu_write_valid,

	input  cpu_read_ack,
	output cpu_read_valid,
	output [31:0] cpu_read_data,

	input sdram_req_ready,
	output sdram_req_valid,

	output sdram_write_valid,

	output sdram_read_ack,
	input sdram_read_valid,
	input [31:0] sdram_read_data,

	input wb_req_ready,
	output wb_req_valid,

	output wb_write_valid,

	output wb_read_ack,
	input wb_read_valid,
	input [31:0] wb_read_data
);

wire sel;

assign sel = (cpu_req_addr[31:28] != 4'd0);

assign wb_req_valid = sel & cpu_req_valid;
assign sdram_req_valid = !sel & cpu_req_valid;

assign cpu_req_ready = sel ? wb_req_ready : sdram_req_ready;

assign wb_write_valid = sel & cpu_write_valid;
assign sdram_write_valid = !sel & cpu_write_valid;

assign cpu_read_valid = sel ? wb_read_valid : sdram_read_valid;
assign cpu_read_data = sel ? wb_read_data : sdram_read_data;

assign wb_read_ack = sel & cpu_read_ack;
assign sdram_read_ack = !sel & cpu_read_ack;

endmodule
