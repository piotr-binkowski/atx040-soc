module fifo(clk, rst, wr, wdata, rd, rdata, empty, full);

parameter SIZE = 1024;
parameter DW   = 32;

parameter AW   = $clog2(SIZE);

input clk;
input rst;

input wr;
input [DW-1:0] wdata;

input rd;
output [DW-1:0] rdata;

output empty;
output full;

wire wr_i = wr && !full;
wire rd_i = rd && !empty;

reg [AW:0]  wptr = 0;
reg [AW:0]  rptr = 0;

wire [AW:0] rptr_mem;
wire [AW:0] rptr_next;

reg empty_i = 1'b1;
assign empty = empty_i;

assign rptr_next = rptr + 1'b1;
assign rptr_mem  = (rd_i) ? rptr_next : rptr;

assign full  = (wptr[AW-1:0] == rptr[AW-1:0]) && (wptr[AW] ^ rptr[AW]);

always @(posedge clk) begin
	if (rst) begin
		empty_i <= 1'b1;
	end else begin
		if((wptr == rptr) || ((wptr == rptr_next) && rd_i))
			empty_i <= 1'b1;
		else
			empty_i <= 1'b0;
	end
end

always @(posedge clk) begin
	if (rst) begin
		wptr <= 0;
		rptr <= 0;
	end else begin
		if (wr_i)
			wptr <= wptr + 1'b1;
		if (rd_i)
			rptr <= rptr + 1'b1;
	end
end

bram #(
	.SIZE(SIZE),
	.DW(DW)
) bram_i (
	.clk(clk),
	.wstrb(wr_i),
	.waddr(wptr[AW-1:0]),
	.wdata(wdata),
	.raddr(rptr_mem[AW-1:0]),
	.rdata(rdata)
);

endmodule
