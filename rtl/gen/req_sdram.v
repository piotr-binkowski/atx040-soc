module req_sdram(
	input clk,
	input rst,

	output init_done,

	input req_valid,
	output req_ready,

	input [3:0] req_mask,
	input [31:0] req_addr,
	input [2:0] req_len,
	input req_we,

	input write_valid,
	input [DW-1:0] write_data,

	output read_valid,
	output [DW-1:0] read_data,
	input read_ack,

	output cke,
	output cs,
	output ras,
	output cas,
	output we,

	inout [15:0] d,
	output [1:0] dm,

	output [12:0] a,
	output [1:0] ba
);

localparam DW = 32;
localparam FIFO_DEPTH = 8;

/* Control channel */

wire sdram_req_we;
wire sdram_req_ready;
wire sdram_req_valid;
wire [3:0] sdram_req_len;
wire [23:0] sdram_req_addr;

wire req_fifo_full;
wire req_fifo_empty;
wire [39:0] req_fifo_out;

assign sdram_req_valid = !req_fifo_empty;
assign req_ready = !req_fifo_full;

assign sdram_req_we   = req_fifo_out[39];
assign sdram_req_addr = {req_fifo_out[24:2], 1'b0};
assign sdram_req_len  = {req_fifo_out[38:36], 1'b0};

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(40)
) fifo_req (
	.clk(clk),
	.rst(rst),
	.wr(req_ready & req_valid),
	.wdata({req_we, req_len, req_mask, req_addr}),
	.rd(sdram_req_ready & sdram_req_valid),
	.rdata(req_fifo_out),
	.empty(req_fifo_empty),
	.full(req_fifo_full)
);

/* Write channel */

reg [3:0] wr_mask;

always @(posedge clk)
	if (sdram_req_ready & sdram_req_valid)
		wr_mask <= req_fifo_out[35:32];

reg wr_mux = 1'b0;

wire write_fifo_rd;
wire write_fifo_empty;
wire [DW-1:0] write_fifo_rdata;

wire sdram_write_valid;
wire sdram_write_ready;
wire [1:0] sdram_write_mask;
wire [15:0] sdram_write_data;

assign sdram_write_mask = (wr_mux) ? wr_mask[1:0] : wr_mask[3:2];
assign sdram_write_data = (wr_mux) ? write_fifo_rdata[15:0] : write_fifo_rdata[31:16];

assign write_fifo_rd = (wr_mux & sdram_write_ready);
assign sdram_write_valid = !write_fifo_empty;

always @(posedge clk) begin
	if(rst) begin
		wr_mux <= 1'b0;
	end else begin
		if(sdram_write_valid & sdram_write_ready) begin
			wr_mux <= !wr_mux;
		end
	end
end


fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_write (
	.clk(clk),
	.rst(rst),
	.wr(write_valid),
	.wdata(write_data),
	.rd(write_fifo_rd),
	.rdata(write_fifo_rdata),
	.empty(write_fifo_empty),
	.full()
);

/* Read channel */


reg rd_mux = 1'b0;
reg [15:0] read_data_buf;

wire read_fifo_wr;
wire read_fifo_empty;
wire [DW-1:0] read_fifo_wdata;

wire sdram_read_valid;
wire [15:0] sdram_read_data;

assign read_fifo_wr = (rd_mux & sdram_read_valid);
assign read_fifo_wdata = {read_data_buf, sdram_read_data};
assign read_valid = !read_fifo_empty;

always @(posedge clk) begin
	if(rst) begin
		rd_mux <= 1'b0;
	end else begin
		if (sdram_read_valid) begin
			if(rd_mux == 1'b0)
				read_data_buf <= sdram_read_data;

			rd_mux <= !rd_mux;
		end
	end
end

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_read (
	.clk(clk),
	.rst(rst),
	.wr(read_fifo_wr),
	.wdata(read_fifo_wdata),
	.rd(read_ack),
	.rdata(read_data),
	.empty(read_fifo_empty),
	.full()
);

sdram sdram_i (
	.clk(clk),
	.rst(rst),

	.init_done(init_done),

	.req_ready(sdram_req_ready),
	.req_valid(sdram_req_valid),
	.req_len(sdram_req_len),
	.req_addr(sdram_req_addr),
	.req_we(sdram_req_we),

	.din(sdram_write_data),
	.din_valid(sdram_write_valid),
	.din_ready(sdram_write_ready),
	.din_mask(sdram_write_mask),

	.dout(sdram_read_data),
	.dout_valid(sdram_read_valid),

	.cke(cke),
	.cs(cs),
	.ras(ras),
	.cas(cas),
	.we(we),
	.data(d),
	.dm(dm),
	.addr(a),
	.baddr(ba)
);

endmodule