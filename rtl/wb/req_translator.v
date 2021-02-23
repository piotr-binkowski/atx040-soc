module req_translator(
	clk_i,
	rst_i,

	req_valid,
	req_ready,

	req_mask,
	req_addr,
	req_len,
	req_we,

	din_valid,
	din,

	dout_valid,
	dout_ack,
	dout,

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
output req_ready;

(* keep = "true" *) input req_we;
(* keep = "true" *) input [2:0] req_len;
(* keep = "true" *) input [AW-1:0] req_addr;
(* keep = "true" *) input [COLS-1:0] req_mask;

input din_valid;
input [DW-1:0] din;

output dout_valid;
input  dout_ack;
output [DW-1:0] dout;

output wb_cyc_o;
output wb_stb_o;
input  wb_ack_i;
output wb_we_o;
output [COLS-1:0] wb_sel_o;
output [AW-3:0] wb_adr_o;
output [DW-1:0] wb_dat_o;
input  [DW-1:0] wb_dat_i;

reg stb_i;
assign wb_cyc_o = stb_i;
assign wb_stb_o = stb_i;

reg we_i;
assign wb_we_o = we_i;

reg [COLS-1:0] sel_i;
assign wb_sel_o = sel_i;

reg [AW-3:0] adr_i;
assign wb_adr_o = adr_i;

wire dout_fifo_full;
wire dout_fifo_empty;

assign dout_valid = !dout_fifo_empty;

wire din_fifo_full;
wire din_fifo_empty;

wire req_fifo_rd;
wire [39:0] req_fifo_out;
wire req_fifo_empty;
wire req_fifo_full;


localparam IDLE = 2'd0, XFER = 2'd1;

reg [1:0] state = IDLE;

reg [2:0] req_len_i;
reg [COLS-1:0] req_mask_i;
reg [AW-1:0] req_addr_i;
reg req_we_i;

assign req_ready = !req_fifo_full;
assign req_fifo_rd = (state == IDLE);

always @(posedge clk_i) begin
	if(rst_i) begin
		state      <= IDLE;
		stb_i      <= 1'b0;

		req_we_i   <= 1'b0;
		req_len_i  <= 4'd0;
		req_mask_i <= 4'd0;
		req_addr_i <= 32'd0;
	end else begin
		case(state)
			IDLE: if(req_fifo_rd && !req_fifo_empty) begin
				req_we_i   <= req_fifo_out[39];
				req_len_i  <= req_fifo_out[38:36];
				req_mask_i <= req_fifo_out[35:32];
				req_addr_i <= req_fifo_out[31:0];
				state      <= XFER;
			end
			XFER: begin
				we_i  <= req_we_i;
				adr_i <= req_addr_i[31:2];
				sel_i <= req_mask_i;
				stb_i <= (!dout_fifo_full & !req_we_i) | (!din_fifo_empty & req_we_i);

				if (wb_stb_o && wb_ack_i) begin
					stb_i           <= 1'b0;
					req_addr_i[3:2] <= req_addr_i[3:2] + 1'b1; 
					req_len_i       <= req_len_i - 1'b1;
					if (req_len_i == 3'b1) begin
						state <= IDLE;
					end
				end
			end
			default: begin
				state <= IDLE;
				stb_i <= 1'b0;
			end
		endcase
	end
end

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(40)
) fifo_req (
	.clk(clk_i),
	.rst(rst_i),
	.wr(req_valid),
	.wdata({req_we, req_len, req_mask, req_addr}),
	.rd(req_fifo_rd),
	.rdata(req_fifo_out),
	.empty(req_fifo_empty),
	.full(req_fifo_full)
);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_din (
	.clk(clk_i),
	.rst(rst_i),
	.wr(din_valid),
	.wdata(din),
	.rd(wb_ack_i & wb_stb_o & wb_we_o),
	.rdata(wb_dat_o),
	.empty(din_fifo_empty),
	.full(din_fifo_full)
);

fifo #(
	.SIZE(FIFO_DEPTH),
	.DW(DW)
) fifo_dout (
	.clk(clk_i),
	.rst(rst_i),
	.wr(wb_ack_i & wb_stb_o & !wb_we_o),
	.wdata(wb_dat_i),
	.rd(dout_ack),
	.rdata(dout),
	.empty(dout_fifo_empty),
	.full(dout_fifo_full)
);

endmodule
