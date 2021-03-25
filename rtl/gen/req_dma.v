module req_dma(
	clk, rst,
	base_addr,
	req_valid, req_ready,
	req_len, req_mask, req_addr, req_we, req_wrap,
	write_valid, write_data,
	read_valid, read_data, read_ack,
	dout_valid, dout_ready, dout,
	sync
);

parameter RESX = 640;
parameter RESY = 400;
parameter PIXW = 16;
parameter LW   = 8;

localparam DW  = 32;
localparam AW  = 32;
localparam MW  = 4;
localparam BL  = {1'b1, {(LW-1){1'b0}}};
localparam TGT = (RESX*RESY*PIXW)/DW;

parameter CW = $clog2(TGT);

input      clk;
input      rst;

input      [DW-1:0] base_addr;

output reg req_valid;
input      req_ready;

output     [LW-1:0] req_len;
output     [MW-1:0] req_mask;
output     [AW-1:0] req_addr;
output     req_we;
output     req_wrap;

output     write_valid;
output     [DW-1:0] write_data;

input      read_valid;
input      [DW-1:0] read_data;
output     read_ack;

output     dout_valid;
input      dout_ready;
output     [DW-1:0] dout;

input      sync;

assign req_mask = {(MW){1'b0}};
assign req_len = BL;
assign req_we = 1'b0;
assign req_wrap = 1'b0;

assign write_valid = 1'b0;
assign write_data = {(DW){1'b0}};

wire fifo_empty, fifo_full, fifo_rst, fifo_wr, fifo_rd;

localparam IDLE = 2'd0, REQ = 2'd1, XFER = 2'd2, SYNC = 2'd3;

reg [1:0] state = IDLE;
reg [CW-1:0] cnt = {(CW){1'b0}};
reg [LW-1:0] len;

wire xfer_valid = (state == XFER);

assign req_addr = base_addr + {cnt, 2'b00};

assign read_ack = (!fifo_full) & xfer_valid;
assign dout_valid = !fifo_empty;
assign fifo_rst = sync;

reg [15:0] fifo_lvl = 0;

always @(posedge clk) begin
	if(fifo_rst) begin
		fifo_lvl <= 0;
	end else begin
		if(fifo_wr & !fifo_rd)
			fifo_lvl <= fifo_lvl + 1'b1;
		else if (fifo_rd & !fifo_wr)
			fifo_lvl <= fifo_lvl - 1'b1;
	end
end

always @(posedge clk) begin
	if(rst) begin
		state <= SYNC;
		req_valid <= 1'b0;
	end else begin
		case(state)
			SYNC: if(sync) begin
				state <= IDLE;
				cnt <= {(CW){1'b0}};
			end
			IDLE: if(fifo_lvl < (7*BL)) begin
				len <= BL;
				req_valid <= 1'b1;
				state <= REQ;
			end
			REQ: if(req_valid & req_ready) begin
				state <= XFER;
				req_valid <= 1'b0;
			end
			XFER: if(read_valid & read_ack) begin
				len <= len - 1'b1;
				if(len == 1) begin
					state <= IDLE;
					cnt <= cnt + BL;

					if(cnt >= (TGT - BL)) begin
						state <= SYNC;
					end
				end
			end
		endcase
	end
end

assign fifo_wr = read_valid & xfer_valid & !fifo_full;
assign fifo_rd = dout_ready & !fifo_empty;

fifo #(
	.SIZE(BL*8),
	.DW(DW)
) fifo_i (
	.clk(clk),
	.rst(fifo_rst),
	.wr(fifo_wr),
	.wdata(read_data),
	.rd(fifo_rd),
	.rdata(dout),
	.empty(fifo_empty),
	.full(fifo_full)
);

endmodule
