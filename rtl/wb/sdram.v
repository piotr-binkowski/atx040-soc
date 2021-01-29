module wb_sdram(
	clk_i, rst_i,
	cyc_i, stb_i, adr_i, we_i,
	dat_i, sel_i, ack_o, dat_o,
	cke, cs, ras, cas, we,
	d, dm, a, ba
);

localparam AW   = 23;
localparam DW   = 32;
localparam COLS = DW/8;

input clk_i;
input rst_i;

input cyc_i;
input stb_i;

input [AW-1:0] adr_i;
input we_i;

input [DW-1:0] dat_i;
input [COLS-1:0] sel_i;

output reg [DW-1:0] dat_o;
output reg ack_o = 1'b0;

output cke;
output cs;
output ras;
output cas;
output we;

inout [15:0] d;
output [1:0] dm;

output [12:0] a;
output [1:0] ba;

wire req_ready;
reg req_valid = 1'b0;
reg [3:0] req_len;
reg [23:0] req_addr;
reg req_we;

reg din_mux;
wire [15:0] din;
reg [1:0] din_mask;
reg din_valid = 1'b0;
wire din_ready;

wire [15:0] dout;
wire dout_valid;

sdram sdram_i (
	.clk(clk_i),
	.rst(rst_i),

	.req_ready(req_ready),
	.req_valid(req_valid),
	.req_len(req_len),
	.req_addr(req_addr),
	.req_we(req_we),

	.din(din),
	.din_valid(din_valid),
	.din_ready(din_ready),
	.din_mask(din_mask),

	.dout(dout),
	.dout_valid(dout_valid),

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

localparam IDLE = 3'd0, REQ_ACK = 3'd1, WR0 = 3'd2, WR1 = 3'd3, RD0 = 3'd4, RD1 = 3'd5, ACK = 3'd6;

reg [2:0] state = IDLE;

assign din = (din_mux) ? dat_i[31:16] : dat_i[15:0];

always @(posedge clk_i) begin
	if (rst_i) begin
		state <= IDLE;
		din_mux <= 1'b0;
		req_valid <= 1'b0;
	end else begin
		case(state)
			IDLE: begin
				if(stb_i) begin
					req_valid <= 1'b1;
					req_addr  <= {adr_i, 1'b0};
					req_len   <= 4'd2;
					req_we    <= we_i;
					state     <= REQ_ACK;
				end
			end
			REQ_ACK: begin
				if(req_valid & req_ready) begin
					req_valid <= 1'b0;
					state     <= (we_i) ? WR0 : RD0;
				end
			end
			WR0: begin
				din_mux   <= 1'b0;
				din_mask  <= sel_i[1:0];
				din_valid <= 1'b1;
				if (din_valid & din_ready) begin
					din_mask <= sel_i[3:2];
					din_mux  <= 1'b1;
					state    <= WR1;
				end
			end
			WR1: begin
				if (din_valid & din_ready) begin
					din_valid <= 1'b0;
					state     <= ACK;
				end
			end
			RD0: begin
				if (dout_valid) begin
					dat_o[15:0] <= dout;
					state <= RD1;
				end
			end
			RD1: begin
				if (dout_valid) begin
					dat_o[31:16] <= dout;
					state <= ACK;
				end
			end
			ACK: begin
				ack_o <= 1'b1;
				if (ack_o & stb_i) begin
					ack_o <= 1'b0;
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
