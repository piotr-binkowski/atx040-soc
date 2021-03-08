module req_wb_bridge(
	clk_i,
	rst_i,

	req_valid,
	req_ready,

	req_mask,
	req_addr,
	req_len,
	req_we,

	write_valid,
	write_data,

	read_valid,
	read_data,
	read_ack,

	wb_cyc_o,
	wb_stb_o,
	wb_ack_i,
	wb_we_o,
	wb_sel_o,
	wb_adr_o,
	wb_dat_o,
	wb_dat_i
);

parameter FIFO_DEPTH = 8;

localparam AW   = 32;
localparam DW   = 32;
localparam COLS = DW/8;

input clk_i;
input rst_i;

input  req_valid;
output reg req_ready;

input req_we;
input [2:0] req_len;
input [AW-1:0] req_addr;
input [COLS-1:0] req_mask;

input write_valid;
input [DW-1:0] write_data;

output read_valid;
output [DW-1:0] read_data;
input  read_ack;

output wb_cyc_o;
output wb_stb_o;
input  wb_ack_i;
output reg wb_we_o;
output reg [COLS-1:0] wb_sel_o;
output reg [AW-3:0] wb_adr_o;
output [DW-1:0] wb_dat_o;
input  [DW-1:0] wb_dat_i;

reg wb_stb = 1'b0;
assign wb_cyc_o = wb_stb;
assign wb_stb_o = wb_stb;

wire read_fifo_full;
wire read_fifo_empty;

assign read_valid = !read_fifo_empty;

wire write_fifo_empty;

localparam IDLE = 2'd0, XFER = 2'd1;

reg [1:0] state = IDLE;

reg [2:0] len;

always @(posedge clk_i) begin
	if(rst_i) begin
		state     <= IDLE;
		wb_stb    <= 1'b0;
		req_ready <= 1'b0;
		len       <= 4'd0;
	end else begin
		case(state)
			IDLE: begin 
				req_ready  <= 1'b1;
				if(req_valid & req_ready) begin
					req_ready <= 1'b0;
					wb_we_o   <= req_we;
					wb_sel_o  <= req_mask;
					wb_adr_o  <= req_addr[31:2];
					state     <= XFER;
					len       <= req_len;
				end
			end
			XFER: begin
				wb_stb <= ((!read_fifo_full) & (!wb_we_o)) | ((!write_fifo_empty) & wb_we_o);
				if (wb_stb_o && wb_ack_i) begin
					wb_stb <= 1'b0;
					if (len == 3'b1) begin
						state <= IDLE;
					end else begin
						wb_adr_o[1:0] <= wb_adr_o[1:0] + 1'b1; 
						len           <= len - 1'b1;
					end
				end
			end
			default: begin
				state  <= IDLE;
				wb_stb <= 1'b0;
			end
		endcase
	end
end

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_write (
	.clk(clk_i),
	.rst(rst_i),
	.wr(write_valid),
	.wdata(write_data),
	.rd(wb_ack_i & wb_stb_o & wb_we_o),
	.rdata(wb_dat_o),
	.empty(write_fifo_empty),
	.full()
);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_read (
	.clk(clk_i),
	.rst(rst_i),
	.wr(wb_ack_i & wb_stb_o & !wb_we_o),
	.wdata(wb_dat_i),
	.rd(read_ack),
	.rdata(read_data),
	.empty(read_fifo_empty),
	.full(read_fifo_full)
);

endmodule
