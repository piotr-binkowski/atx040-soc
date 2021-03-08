module cpuif (
	input  wire clk_i,
	input  wire rst_i,

	input  wire bclk,

	input  wire cdis_ext,

	inout  wire [31:0] cpu_ad,

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

	output reg  req_valid,
	input  wire req_ready,
	output reg  [2:0] req_len,
	output reg  [3:0] req_mask,
	output reg  [31:0] req_addr,
	output reg  req_we,

	output reg  write_valid,
	output reg  [31:0] write_data,

	input  wire read_valid,
	input  wire [31:0] read_data,
	output reg  read_ack,

	/* Interrupt controller */

	input  wire irq_req,
	input  wire [7:0] irq_vec,
	output wire irq_ack
);

parameter ROM_OFF = 16'h4000;

assign cpu_irq  = ~irq_req;

/* Phase detect */

reg bclk_phase = 0;
reg clk_phase  = 0;

reg [1:0] phase = 0;

always @(posedge bclk) begin
	bclk_phase <= ~bclk_phase;
end

always @(posedge clk_i) begin
	clk_phase <= bclk_phase;
end

always @(posedge clk_i) begin
	if(clk_phase ^ bclk_phase) begin
		phase <= 2;
	end else begin
		phase <= phase + 1'b1;
	end
end

/* Reset */

wire rst_cpu;
wire rst_fsm;

reg [10:0] rst_cnt = 0;

always @(posedge clk_i) begin
	if(rst_i) begin
		rst_cnt <= 0;
	end else if (rst_cnt < 1024) begin
		rst_cnt <= rst_cnt + 1'b1;
	end
end

assign rst_cpu  = rst_cnt > (256)  ? 1'b0 : 1'b1;
assign rst_fsm  = rst_cnt > (256+512+8) ? 1'b0 : 1'b1;

reg [3:0] cdis_ext_sync = 4'b1111;

always @(posedge bclk)
	cdis_ext_sync <= {cdis_ext_sync[2:0], cdis_ext};

assign cpu_cdis = !(rst_fsm | cdis_ext_sync[3]);

assign cpu_rsti = ~rst_cpu;

/* Bus */

parameter IDLE = 4'd0, IRQ0 = 4'd1, IRQ1 = 4'd2, IRQ2 = 4'd3, IRQ3 = 4'd4, WAIT = 4'd5, READ0 = 4'd8, READ1 = 4'd9, READ2 = 4'd10, READ3 = 4'd11, WRITE0 = 4'd12, WRITE1 = 4'd13, WRITE2 = 4'd14, WRITE3 = 4'd15;

parameter SIZ_BYTE = 2'b01, SIZ_WORD = 2'b10, SIZ_LONG = 2'b00, SIZ_LINE = 2'b11;

parameter TT_DEF = 2'b00, TT_MOVE16 = 2'b01, TT_ALT = 2'b10, TT_ACK = 2'b11;

(* keep = "true" *) reg [3:0] state  = IDLE;

reg ta_o;
assign cpu_ta    = ta_o;

wire [31:0] addr_i;
assign addr_i    = {
		cpu_ad[3],  cpu_ad[2],  cpu_ad[4],  cpu_ad[7],
		cpu_ad[1],  cpu_ad[6],  cpu_ad[9],  cpu_ad[0],
		cpu_ad[11], cpu_ad[5],  cpu_ad[8],  cpu_ad[10],
		cpu_ad[16], cpu_ad[12], cpu_ad[13], cpu_ad[18],
		cpu_ad[14], cpu_ad[15], cpu_ad[17], cpu_ad[19],
		cpu_ad[20], cpu_ad[21], cpu_ad[29], cpu_ad[31],
		cpu_ad[30], cpu_ad[27], cpu_ad[28], cpu_ad[26],
		cpu_ad[24], cpu_ad[25], cpu_ad[22], cpu_ad[23]
	};

reg ad_t = 1;
reg [31:0] dat_i = 0;
assign cpu_ad = (ad_t) ? {32{1'bZ}} : dat_i;

reg dir_i        = 1;
assign cpu_dir   = dir_i;

reg oe_i         = 1;
assign cpu_oe    = oe_i;

reg ack_i        = 0;
assign irq_ack   = ack_i;

reg [1:0] acc_cnt = 2'b00;
wire force_rom = (acc_cnt < 2'b10);

always @(posedge clk_i) begin
	if(rst_fsm) begin
		state       <= IDLE;
		dir_i       <= 1'b1;
		oe_i        <= 1'b0;
		ad_t        <= 1'b1;
		ta_o        <= 1'b1;
		ack_i       <= 1'b0;
		req_valid   <= 1'b0;
		write_valid <= 1'b0;
		read_ack    <= 1'b0;
		acc_cnt     <= 2'b00;
	end else begin
		write_valid <= 1'b0;
		read_ack    <= 1'b0;

		case(state)
			IDLE: if(phase == 0 && (~cpu_ts)) begin
				if((cpu_tt == TT_DEF) || (cpu_tt == TT_MOVE16)) begin
					req_len <= 3'd1;
					case(cpu_siz)
						SIZ_BYTE: begin
							case(addr_i[1:0])
								2'b00:
									req_mask <= 4'b1000;
								2'b01:
									req_mask <= 4'b0100;
								2'b10:
									req_mask <= 4'b0010;
								2'b11:
									req_mask <= 4'b0001;
							endcase
						end
						SIZ_WORD: begin
							req_mask <= (addr_i[1]) ? 4'b0011 : 4'b1100;
						end
						SIZ_LONG: begin
							req_mask <= 4'b1111;
						end
						SIZ_LINE: begin
							req_mask <= 4'b1111;
							req_len  <= 3'd4;
						end
					endcase
					req_addr  <= addr_i;
					req_we    <= !cpu_rw;
					req_valid <= 1'b1;

					if (force_rom) begin
						req_addr <= {ROM_OFF, addr_i[15:0]};
						acc_cnt  <= acc_cnt + 1'b1;
					end

					state <= WAIT;

				end else if(cpu_tt == TT_ACK) begin
					dat_i <= {24'd0, irq_vec};
					ack_i <= 1'b1;
					state <= IRQ0;
				end
			end

			WAIT: begin
				req_valid <= 1'b1;
				if(req_ready & req_valid) begin
					req_valid <= 1'b0;
					state <= (cpu_rw) ? READ0 : WRITE0;
				end
			end

			IRQ0: if(phase == 1) begin
				ack_i <= 1'b0;
				state <= IRQ1;
			end
			IRQ1: if(phase == 2) begin
				dir_i <= 1'b0;
				state <= IRQ2;
			end
			IRQ2: if(phase == 1) begin
				ad_t  <= 1'b0;
				ta_o  <= 1'b0;
				state <= IRQ3;
			end
			IRQ3: if(phase == 1) begin
				dir_i <= 1'b1;
				ad_t  <= 1'b1;
				ta_o  <= 1'b1;
				state <= IDLE;
			end

			READ0: if(phase == 2) begin
				dir_i <= 1'b0;
				state <= READ1;
			end
			READ1: if(phase == 2) begin
				if(read_valid) begin
					dat_i    <= read_data;
					read_ack <= 1'b1;
					ad_t     <= 1'b0;
					ta_o     <= 1'b0;
					state    <= READ2;
				end
			end
			READ2: if(phase == 1) begin
				if(req_len == 3'd1) begin
					state <= IDLE;
					dir_i <= 1'b1;
					ad_t  <= 1'b1;
					ta_o  <= 1'b1;
				end else begin
					req_len <= req_len - 1'b1;
					state   <= READ1;
					ta_o    <= 1'b1;
				end
			end

			WRITE0: if(phase == 2) begin
				ta_o <= 1'b0;
				state <= WRITE1;
			end
			WRITE1: if(phase == 0) begin
				write_valid <= 1'b1;
				write_data  <= cpu_ad;
				state       <= WRITE2;
			end
			WRITE2: if(phase == 1) begin
				if(req_len == 3'd1) begin
					ta_o  <= 1'b1;
					state <= IDLE;
				end else begin
					state   <= WRITE1;
					req_len <= req_len - 1'b1;
				end
			end

			default: state <= IDLE;
		endcase
	end
end

endmodule
