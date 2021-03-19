module sdram(
	clk, rst,
	init_done,
	req_ready, req_valid, req_len, req_addr, req_we,
	din, din_valid, din_ready, din_mask,
	dout, dout_valid,
	cke, cs, ras, cas, we,
	data, dm, addr, baddr
);

parameter TCK   = 10;
parameter ROWS  = 8192;
parameter COLS  = 512;
parameter BANKS = 4;

parameter RW = $clog2(ROWS);
parameter CW = $clog2(COLS);
parameter BW = $clog2(BANKS);
parameter DW = 16;

localparam AW = RW+CW+BW;
localparam MW = DW/8;

input clk;
input rst;

output init_done;

output req_ready;
input req_valid;
input [3:0] req_len;
input [AW-1:0] req_addr;
input req_we;

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

inout  [DW-1:0] data;
output [MW-1:0] dm;

output [RW-1:0] addr;
output [BW-1:0] baddr;

reg  [RW-1:0] addr_o;
reg  [BW-1:0] baddr_o;
reg  [DW-1:0] data_o;
wire [DW-1:0] data_i;
reg  [MW-1:0] dm_o;
reg data_t = 1'b1;

genvar i;
generate
	for (i = 0; i < RW; i = i + 1) begin : a_oreg_gen
		oreg oreg_a_i (clk, addr[i], addr_o[i]);
	end
	for (i = 0; i < BW; i = i + 1) begin : ba_oreg_gen
		oreg oreg_ba_i (clk, baddr[i], baddr_o[i]);
	end
	for (i = 0; i < MW; i = i + 1) begin : dm_oreg_gen
		oreg oreg_dm_i (clk, dm[i], dm_o[i]);
	end
	for (i = 0; i < DW; i = i + 1) begin : d_ioreg_gen
		ioreg ioreg_d_i (clk, data[i], data_o[i], data_i[i], data_t);
	end
endgenerate

assign cke = 1'b1;

reg [3:0] cmd_o = 4'b1111;

oreg oreg_cs_i (clk, cs, cmd_o[3]);
oreg oreg_ras_i (clk, ras, cmd_o[2]);
oreg oreg_cas_i (clk, cas, cmd_o[1]);
oreg oreg_we_i (clk, we, cmd_o[0]);

/* Init delay */

reg [14:0] init_cnt = 15'd0;
wire init_dly = (init_cnt < 15'h4000);

always @(posedge clk) begin
	if (rst)
		init_cnt <= 15'd0;
	else if (init_dly)
		init_cnt <= init_cnt + 1'b1;
end

/* Refresh */

reg ref_en = 1'b0;
reg [9:0] ref_cnt = 10'h000;
wire ref_trg = (ref_cnt == 10'h300);
reg ref_req = 1'b0;
wire ref_ack;

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

localparam TRFC = (60 - 1) / TCK + 1, TRP  = (20 - 1) / TCK + 1;
localparam TMRD = (20 - 1) / TCK + 1, TRAS = (50 - 1) / TCK + 1;
localparam TRC  = (60 - 1) / TCK + 1, TRCD = (20 - 1) / TCK + 1;
localparam TRRD = (20 - 1) / TCK + 1, TWR  = (20 - 1) / TCK + 1;

localparam WB_S = 1'b1, WB_BL = 1'b0, OP_STD = 2'b00, CL2 = 3'b010,
	   CL3 = 3'b011, BT_SEQ = 1'b0, BL2 = 3'b001, BL1 = 3'b000;

localparam CL = 2;

reg [4:0] state = S_INOP;
reg [3:0] cmd_d = 4'd1;

assign ref_ack = ((state == S_IDLE) && (ref_req));

assign req_ready = ((state == S_IDLE) && (!ref_req));

assign din_ready = (state == S_WR);

assign init_done = ref_en;

reg [AW-1:0] addr_i;
reg [3:0] len_i;
reg we_i;

reg [CL+1:0] dvalid = {(CL+1){1'b0}};

assign dout_valid = dvalid[0];
assign dout = data_i;

always @(posedge clk) begin
	if (rst) begin
		state  <= S_INOP;
		cmd_o  <= NOP;
		data_t <= 1'b1;
		cmd_d  <= 4'd1;
		ref_en <= 1'b0;
	end else begin
		cmd_d  <= cmd_d + 1'b1;
		dvalid <= {1'b0, dvalid[CL+1:1]};
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
					addr_o[10] <= 1'b1;
					cmd_o      <= PRE;
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
					addr_o  <= {3'b000, WB_BL, OP_STD, (CL == 2) ? CL2 : CL3, BT_SEQ, BL1};
					baddr_o <= 2'b00;
					cmd_o   <= LMR;
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
					we_i   <= req_we;
				end
			end
			S_REF: begin
				if (cmd_d == 4'd1) begin
					cmd_o <= REF;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRFC) begin
					cmd_d <= 4'd1;
					state <= S_IDLE;
				end
			end
			S_ACT: begin
				if (cmd_d == 4'd1) begin
					cmd_o   <= ACT;
					addr_o  <= addr_i[AW-1-BW:CW];
					baddr_o <= addr_i[AW-1:AW-BW];
				end else
					cmd_o <= NOP;

				if (cmd_d == TRCD) begin
					cmd_d <= 4'd1;
					if (we_i) begin
						data_t <= 1'b0;
						state <= S_WR;
					end else begin
						data_t <= 1'b1;
						state <= S_RD;
					end
				end
			end
			S_WR: begin
				cmd_o <= NOP;

				if (din_valid) begin
					cmd_o          <= WRITE;
					addr_i[2:0] <= addr_i[2:0] + 1'b1;
					len_i          <= len_i - 1'b1;
				end

				addr_o         <= addr_i[CW-1:0];
				data_o         <= din;
				dm_o           <= ~din_mask;

				if (len_i == 4'd1) begin
					cmd_d <= 4'd1;
					state <= S_WREC;
				end
			end
			S_WREC: begin
				cmd_o <= NOP;
				//dm_o  <= 2'b11;
				if (cmd_d == TWR) begin
					cmd_d <= 4'd1;
					state <= S_PRE;
				end
			end
			S_RD: begin
				cmd_o          <= READ;
				addr_o         <= addr_i[CW-1:0];
				addr_i[2:0]    <= addr_i[2:0] + 1'b1;
				dvalid[CL+1]   <= 1'b1;
				dm_o           <= 2'b00;
				len_i          <= len_i - 1'b1;

				if (len_i == 4'd1) begin
					cmd_d <= 4'd1;
					state <= S_RREC;
				end
			end
			S_RREC: begin
				cmd_o <= NOP;
				//dm_o  <= 2'b11;
				if (cmd_d == CL) begin
					cmd_d <= 4'd1;
					state <= S_PRE;
				end
			end
			S_PRE: begin
				if (cmd_d == 4'd1) begin
					addr_o[10] <= 1'b1;
					cmd_o      <= PRE;
				end else
					cmd_o <= NOP;

				if (cmd_d == TRP) begin
					cmd_d <= 4'd1;
					state <= S_IDLE;
				end
			end
		endcase
	end
end

endmodule
