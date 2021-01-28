module sdram(
	clk, rst,
	req_ready, req_valid, req_len, req_addr, req_dir,
	din, din_valid, din_ready, din_mask,
	dout, dout_valid,
	cke, cs, ras, cas, we,
	data, dm, addr, baddr
);

parameter ROWS  = 8192;
parameter COLS  = 512;
parameter BANKS = 4;

parameter RW = $clog2(ROWS);
parameter CW = $clog2(COLS);
parameter BW = $clog2(BANKS);
parameter DW = 16;

localparam AW = RW+CW+BW;
localparam MW = DW/8;

output req_ready;
input req_valid;
input [3:0] req_len;
input [AW-1:0] req_addr;
input req_dir;

input [DW-1:0] din;
input [MW-1:0] din_mask;
input din_valid;
output din_ready;

output [DW-1:0] dout;
output dout_valid;

output cke;
output cs;
output ras;
output cas;
output we;

inout [DW-1:0] data;
output reg [MW-1:0] dm;

output reg [RW-1:0] addr;
output reg [BW-1:0] baddr;

reg data_t = 1'b1;
reg [DW-1:0] data_o = {DW{1'b0}};
assign data = (data_t) ? {DW{1'bZ}} : data_o;

assign cke = 1'b1;

reg [3:0] cmd_o = 4'b1111;
assign {cs, ras, cas, we} = cmd_o;

/* Init delay */

reg [14:0] init_cnt = 15'd0;
wire init_dly = (init_cnt < 15'h4000);

always @(posedge clk) begin
	if (rst) begin
		init_cnt <= 15'd0;
	else if (init_dly)
		init_cnt <= init_cnt + 1'b1;
end

/* Refresh */

reg ref_en = 1'b0;
reg [9:0] ref_cnt = 10'h000;
wire ref_trg = (ref_cnt == 10'h300);
reg ref_req = 1'b0;
wire ref_ack = 1'b0;

always @(posedge clk)
	if ((!ref_en) || ref_trg)
		ref_cnt <= 10'h000;
	else
		ref_cnt <= ref_cnt + 1'b1;

always @(posedge clk)
	if ((!ref_en) || ref_ack)
		ref_req <= 1'b0;
	else if (ref_trg)
		ref_req <= 1'b1;


/* FSM */

localparam NOP = 4'b0111, ACT = 4'b0011, READ = 4'b0101, WRITE = 4'b0100,
	   BTE = 4'b0110, PRE = 4'b0010, REF = 4'b0001, LMR = 4'b0000;

localparam S_INOP = 5'd0, S_IPRE = 5'd1, S_IREF0 = 5'd2, S_IREF1 = 5'd3,
	   S_ILMR = 5'd4, S_IDLE = 5'd5, S_REF = 5'd6, S_PRE = 5'd7, S_ACT = 5'd8,
	   S_WR = 5'd9, S_RD = 5'd10, S_RREC = 5'd11, S_WREC = 5'd12;

localparam TRFC = 4'd6, TRP = 4'd2, TMRD = 4'd2, TRAS = 4'd5, TRC = 4'd6, TRCD = 4'd2, TRRD = 4'd2, TWR = 4'd2;

localparam WB_S = 1'b1, WB_BL = 1'b0, OP_STD = 2'b00, CL2 = 3'b010,
	   CL3 = 3'b011, BT_SEQ = 1'b0, BL2 = 3'b001, BL1 = 3'b000;

reg [4:0] state = INIT_NOP;
reg [3:0] cmd_d = 4'd1;

assign ref_ack = ((state == IDLE) && (ref_req));

assign req_ready = ((state == IDLE) && (!ref_req));

assign din_ready = (state == S_WR);

reg [AW-1:0] addr_i;
reg [3:0] len_i;
reg dir_i;

reg [3:0] dvalid = 4'b0000;
assign dout_valid = dvalid[0];
assign dout = data;

localparam CL = 2;

always @(posedge clk) begin
	if (rst) begin
		state  <= INIT_NOP;
		cmd_o  <= NOP;
		data_t <= 1'b1;
		cmd_d  <= 4'd1;
		ref_en <= 1'b0;
	end else
		cmd_d  <= cmd_d + 1'b1;
		dvalid <= {1'b0, dvalid[3:1]};
		case(state)
			S_INOP: begin
				cmd_o <= NOP;
				if (!init_dly) begin
					cmd_d <= 4'd1;
					state <= S_IPRE;
				end
			end
			S_IPRE: begin
				if (cmd_d == 4'd1) begin
					addr[10] <= 1'b1;
					cmd_o <= PRE;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRP) begin
					cmd_d <= 4'd1;
					state <= S_IREF0;
				end
			end
			S_IREF0: begin
				if (cmd_d == 4'd1) begin
					cmd_o <= REF;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRFC) begin
					cmd_d <= 4'd1;
					state <= S_IREF1;
				end
			end
			S_IREF1: begin
				if (cmd_d == 4'd1) begin
					cmd_o <= REF;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRFC) begin
					cmd_d <= 4'd1;
					state <= S_ILMR;
				end
			end
			S_ILMR: begin
				if (cmd_d == 4'd1) begin
					addr  <= {3'b000, WB_BL, OP_STD, (CL == 2) ? CL2 : CL3, BT_SEQ, BL1};
					baddr <= 2'b00;
					cmd_o <= LMR;
				end else
					cmd_o <= NOP;

				if (cmd_d == TMRD) begin
					cmd_d  <= 4'd1;
					state  <= S_IDLE;
					ref_en <= 1'b1;
				end
			end
			S_IDLE: begin
				cmd_o <= NOP;
				cmd_d <= 4'd1;
				if (ref_req) begin
					state <= S_REF;
				end else if (req_valid) begin
					state  <= S_ACT;
					addr_i <= req_addr;
					len_i  <= req_len;
					dir_i  <= req_dir;
				end
			end
			S_REF: begin
				if (cmd_d = 4'd1) begin
					cmd_o <= REF;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRFC) begin
					cmd_d <= 4'd1;
					state <= IDLE;
				end
			end
			S_ACT: begin
				if (cmd_d = 4'd1) begin
					cmd_o <= ACT;
					addr  <= addr_i[AW-1-BW:CW];
					baddr <= addr_i[AW-1:AW-BW];
				end else
					cmd_o <= NOP;

				if (cmd_d == TRCD) begin
					cmd_d <= 4'd1;
					if (dir_i) begin
						data_t <= 1'b0;
						state <= S_WR;
					end else begin
						data_t <= 1'b1;
						state <= S_RD;
					end
				end
			end
			S_WR: begin
				cmd_o          <= (din_valid) ? WRITE : NOP;
				addr           <= addr_i[CW-1:0];
				addr_i[CW-1:0] <= addr_i[CW-1:0] + 1'b1;
				data_o         <= din;
				dm             <= din_mask;
				len_i          <= len_i - 1'b1;

				if (len_i == 4'd1) begin
					cmd_d <= 4'd1;
					state <= S_WREC;
				end
			end
			S_WREC: begin
				cmd_o <= NOP;
				dm    <= 2'b11;
				if (cmd_d == TWR) begin
					cmd_d <= 4'd1;
					state <= S_PRE;
				end
			end
			S_RD: begin
				cmd_o      <= READ;
				dvalid[CL] <= 1'b1;
				dm         <= 2'b00;
				len_i      <= len_i - 1'b1;

				if (len_i == 4'd1) begin
					cmd_d <= 4'd1;
					state <= S_RREC;
				end
			end
			S_RREC: begin
				cmd_o <= NOP;
				dm    <= 2'b11;
				if (cmd_d == CL) begin
					cmd_d <= 4'd1;
					state <= S_PRE;
				end
			end
			S_PRE: begin
				if (cmd_d == 4'd1) begin
					addr[10] <= 1'b1;
					cmd_o <= PRE;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRP) begin
					cmd_d <= 4'd1;
					state <= IDLE;
				end
			end
		endcase
	end
end

endmodule
