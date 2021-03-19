module req_decoder(
	req_valid, req_ready, req_addr,
	write_valid,
	read_ack, read_valid, read_data,

	slv_req_valid, slv_req_ready,
	slv_write_valid,
	slv_read_ack, slv_read_valid, slv_read_data
);

parameter SLAVES = 16;
parameter SW = $clog2(SLAVES);

localparam DW = 32;

input  req_valid;
input  [SW-1:0] req_addr;
output reg req_ready;

input  write_valid;

input  read_ack;
output reg read_valid;
output reg [DW-1:0] read_data;

output reg [SLAVES-1:0] slv_req_valid;
input  [SLAVES-1:0] slv_req_ready;

output reg [SLAVES-1:0] slv_write_valid;

output reg [SLAVES-1:0] slv_read_ack;
input  [SLAVES-1:0] slv_read_valid;
input  [SLAVES*DW-1:0] slv_read_data;

integer i;

always @(*) begin
	req_ready = 0;
	read_valid = 0;
	slv_req_valid = 0;
	slv_write_valid = 0;
	slv_read_ack = 0;
	for (i = 0; i < SLAVES; i = i+1) begin
		if(req_addr == i) begin
			slv_req_valid[i] = req_valid;
			req_ready = slv_req_ready[i];
			slv_write_valid[i] = write_valid;
			slv_read_ack[i] = read_ack;
			read_valid = slv_read_valid[i];
			read_data = slv_read_data[i*DW+:DW];
		end
	end
end

endmodule
