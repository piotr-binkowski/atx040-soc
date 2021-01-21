module cpuif (
	input  wire clk,
	input  wire bclk,

	input  wire reset,

	output wire [31:0] cpu_ad_i,
	input  wire [31:0] cpu_ad_o,
	output wire cpu_ad_t,

	output wire cpu_dir,
	output wire cpu_oe,

	input  wire [1:0] cpu_siz,
	input  wire [1:0] cpu_tt,
	input  wire cpu_rsto,
	input  wire cpu_tip,
	input  wire cpu_ts,
	input  wire cpu_rw,

	output wire cpu_cdis,
	output wire cpu_rsti,
	output wire cpu_irq,
	output wire cpu_ta,

	/* Wishbone bus */

	output wire wb_cyc_o,
	output wire wb_stb_o,
	input  wire wb_ack_i,
	output wire wb_we_o,
	output wire [3:0] wb_sel_o,

	output wire [29:0] wb_adr_o,

	output wire [31:0] wb_dat_o,
	input  wire [31:0] wb_dat_i
);

assign cpu_irq  = 1;

/* Phase detect */

reg bclk_phase = 0;
reg clk_phase  = 0;

reg [1:0] phase = 0;

always @(posedge bclk) begin
	bclk_phase <= ~bclk_phase;
end

always @(posedge clk) begin
	clk_phase <= bclk_phase;
end

always @(posedge clk) begin
	if(clk_phase ^ bclk_phase) begin
		phase <= 2;
	end else begin
		phase <= phase + 1;
	end
end

/* Reset */

wire rst_cpu;
wire rst_fsm;

reg [10:0] rst_cnt = 0;

always @(posedge clk) begin
	if(reset) begin
		rst_cnt <= 0;
	end else if (rst_cnt < 1024) begin
		rst_cnt <= rst_cnt + 1;
	end
end

assign rst_cpu  = rst_cnt > (256)  ? 1'b0 : 1'b1;
assign rst_fsm  = rst_cnt > (256+512+8) ? 1'b0 : 1'b1;

assign cpu_cdis = ~rst_fsm;

assign cpu_rsti = ~rst_cpu;

/* Bus */

parameter IDLE = 4'd0, READ0 = 4'd8, READ1 = 4'd9, READ2 = 4'd10, READ3 = 4'd11, WRITE0 = 4'd12, WRITE1 = 4'd13, WRITE2 = 4'd14, WRITE3 = 4'd15;

parameter SIZ_BYTE = 2'b01, SIZ_WORD = 2'b10, SIZ_LONG = 2'b00, SIZ_LINE = 2'b11;

parameter TT_DEF = 2'b00, TT_MOVE16 = 2'b01, TT_ALT = 2'b10, TT_ACK = 2'b11;

reg [3:0] state  = IDLE;

reg [31:0] dat_o;
assign wb_dat_o  = dat_o;

reg stb_o;
assign wb_stb_o  = stb_o;
assign wb_cyc_o  = stb_o;

reg [31:0] adr_o;
assign wb_adr_o  = adr_o[31:2];

reg we_o;
assign wb_we_o   = we_o;

reg [3:0] sel_o;
assign wb_sel_o  = sel_o;

reg ta_o;
assign cpu_ta    = ta_o;

wire [31:0] addr_i;
assign addr_i    = {
		cpu_ad_o[3],  cpu_ad_o[2],  cpu_ad_o[4],  cpu_ad_o[7],
		cpu_ad_o[1],  cpu_ad_o[6],  cpu_ad_o[9],  cpu_ad_o[0],
		cpu_ad_o[11], cpu_ad_o[5],  cpu_ad_o[8],  cpu_ad_o[10],
		cpu_ad_o[16], cpu_ad_o[12], cpu_ad_o[13], cpu_ad_o[18],
		cpu_ad_o[14], cpu_ad_o[15], cpu_ad_o[17], cpu_ad_o[19],
		cpu_ad_o[20], cpu_ad_o[21], cpu_ad_o[29], cpu_ad_o[31],
		cpu_ad_o[30], cpu_ad_o[27], cpu_ad_o[28], cpu_ad_o[26],
		cpu_ad_o[24], cpu_ad_o[25], cpu_ad_o[22], cpu_ad_o[23]
	};

reg [31:0] dat_i = 0;
assign cpu_ad_i  = dat_i;

reg dir_i        = 1;
assign cpu_dir   = dir_i;

reg oe_i         = 1;
assign cpu_oe    = oe_i;

reg ad_t_i       = 1;
assign cpu_ad_t  = ad_t_i;

reg [2:0] xfer_len;

always @(posedge clk) begin
	if(rst_fsm) begin
		state  <= IDLE;
		stb_o  <= 1'b0;
		dir_i  <= 1'b1;
		oe_i   <= 1'b0;
		ad_t_i <= 1'b1;
		ta_o   <= 1'b1;
	end else begin
		case(state)
			IDLE: if(phase == 0 && (~cpu_ts)) begin
				case(cpu_tt)
					TT_DEF: begin
						case(cpu_siz)
							SIZ_BYTE: begin
								xfer_len <= 3'd1;
								case(addr_i[1:0])
									2'b00:
										sel_o <= 4'b1000;
									2'b01:
										sel_o <= 4'b0100;
									2'b10:
										sel_o <= 4'b0010;
									2'b11:
										sel_o <= 4'b0001;
								endcase
							end
							SIZ_WORD: begin
								xfer_len <= 3'd1;
								if(addr_i[1] == 1'b1)
									sel_o <= 4'b0011;
								else
									sel_o <= 4'b1100;
							end
							SIZ_LONG: begin
								xfer_len <= 3'd1;
								sel_o    <= 4'b1111;
							end
							SIZ_LINE: begin
								xfer_len <= 3'd4;
								sel_o    <= 4'b1111;
							end
						endcase
						adr_o <= addr_i;
						if(cpu_rw == 1'b0) begin
							state <= WRITE0;
						end else begin
							state <= READ0;
						end
					end
					default: begin

					end
				endcase
			end

			READ0: if(phase == 1) begin
				stb_o <= 1'b1;
				we_o  <= 1'b0;
				state <= READ1;
			end
			READ1: if(wb_ack_i && stb_o) begin
				dir_i <= 1'b0;
				stb_o <= 1'b0;
				we_o  <= 1'b0;
				dat_i <= wb_dat_i;
				state <= READ2;
			end
			READ2:  if(phase == 1) begin
				ad_t_i <= 1'b0;
				ta_o   <= 1'b0;
				state <= READ3;
			end
			READ3:  if(phase == 1) begin
				dir_i  <= 1'b1;
				ad_t_i <= 1'b1;
				ta_o   <= 1'b1;
				if(xfer_len == 3'd1) begin
					state <= IDLE;
				end else begin
					state      <= READ0;
					xfer_len   <= xfer_len - 1;
					adr_o[3:2] <= adr_o[3:2] + 1'b1;
				end
			end

			WRITE0: if(phase == 0) begin
				dat_o <= cpu_ad_o;
				stb_o <= 1'b1;
				we_o  <= 1'b1;
				state <= WRITE1;
			end
			WRITE1: if(wb_ack_i && stb_o) begin
				stb_o <= 1'b0;
				we_o  <= 1'b0;
				state <= WRITE2;
			end
			WRITE2: if(phase == 2) begin
				ta_o  <= 1'b0;
				state <= WRITE3;
			end
			WRITE3: if(phase == 1) begin
				ta_o  <= 1'b1;
				if(xfer_len == 3'd1) begin
					state <= IDLE;
				end else begin
					state      <= WRITE0;
					xfer_len   <= xfer_len - 1;
					adr_o[3:2] <= adr_o[3:2] + 1'b1;
				end
			end

			default: state <= IDLE;
		endcase
	end
end

endmodule
