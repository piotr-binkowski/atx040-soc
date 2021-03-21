module req_arbiter(
	clk, rst,

	m_req_valid, m_req_ready,
	m_req_len, m_req_mask, m_req_addr, m_req_we, m_req_wrap,
	m_write_valid, m_write_data,
	m_read_valid, m_read_data, m_read_ack,

	req_ready, req_valid,
	req_len, req_mask, req_addr, req_we, req_wrap,
	write_valid, write_data,
	read_valid, read_data, read_ack
);

parameter MASTERS = 2;
parameter MSTW = $clog2(MASTERS);

localparam LW = 3;
localparam MW = 4;
localparam AW = 32;
localparam DW = 32;

input      clk;
input      rst;

input      [MASTERS-1:0] m_req_valid;
output reg [MASTERS-1:0] m_req_ready;

input      [LW*MASTERS-1:0] m_req_len;
input      [MW*MASTERS-1:0] m_req_mask;
input      [AW*MASTERS-1:0] m_req_addr;
input      [MASTERS-1:0] m_req_we;
input      [MASTERS-1:0] m_req_wrap;

input      [MASTERS-1:0] m_write_valid;
input      [DW*MASTERS-1:0] m_write_data;

output reg [MASTERS-1:0] m_read_valid;
output     [DW*MASTERS-1:0] m_read_data;
input      [MASTERS-1:0] m_read_ack;

input      req_ready;
output reg req_valid;

output reg [LW-1:0] req_len;
output reg [MW-1:0] req_mask;
output reg [AW-1:0] req_addr;
output reg req_we;
output reg req_wrap;

output reg write_valid;
output reg [DW-1:0] write_data;

input      read_valid;
input      [DW-1:0] read_data;
output reg read_ack;

reg [MSTW-1:0] master_sel = {(MSTW){1'b0}};

localparam IDLE = 2'd0, REQ = 2'd1, READ = 2'd2, WRITE = 2'd3;

reg [1:0] state = IDLE;

reg [LW-1:0] xfer_len = {(LW){1'b0}};
reg xfer_we = 1'b0;

reg req_en = 1'b0;
reg rd_en = 1'b0;
reg wr_en = 1'b0;

integer i;

always @(posedge clk) begin
	if(rst) begin
		master_sel <= {(MSTW){1'b0}};
		state <= IDLE;
		req_en <= 1'b0;
		rd_en <= 1'b0;
		wr_en <= 1'b0;
	end else begin
		case(state)
			IDLE: for(i = 0; i < MASTERS; i = i+1) begin
				if(m_req_valid[i]) begin
					xfer_len <= m_req_len[i*LW+:LW];
					xfer_we <= m_req_we[i];
					master_sel <= i;

					state <= REQ;
					req_en <= 1'b1;
				end
			end
			REQ: if(req_valid & req_ready) begin
				req_en <= 1'b0;
				if(xfer_we) begin
					state <= WRITE;
					wr_en <= 1'b1;
				end else begin
					state <= READ;
					rd_en <= 1'b1;
				end
			end
			WRITE: if(write_valid) begin
				xfer_len <= xfer_len - 1'b1;
				if(xfer_len == 1) begin
					wr_en <= 1'b0;
					state <= IDLE;
				end
			end
			READ: if(read_valid & read_ack) begin
				xfer_len <= xfer_len - 1'b1;
				if(xfer_len == 1) begin
					rd_en <= 1'b0;
					state <= IDLE;
				end
			end
		endcase
	end
end

assign m_read_data = {(MASTERS){read_data}};

always @(*) begin
	m_req_ready = {(MASTERS){1'b0}};
	req_valid = 1'b0;
	req_len = {(LW){1'b0}};
	req_mask = {(MW){1'b0}};
	req_addr = {(AW){1'b0}};
	req_we = 1'b0;
	req_wrap = 1'b0;

	write_valid = 1'b0;
	write_data = {(DW){1'b0}};

	m_read_valid = {(MASTERS){1'b0}};
	read_ack = 1'b0;

	for(i = 0; i < MASTERS; i = i+1) begin
		if(master_sel == i) begin
			if(req_en) begin
				m_req_ready[i] = req_ready;
				req_valid = m_req_valid[i];

				req_len = m_req_len[i*LW+:LW];
				req_mask = m_req_mask[i*MW+:MW];
				req_addr = m_req_addr[i*AW+:AW];
				req_we = m_req_we[i];
				req_wrap = m_req_wrap[i];
			end

			if(wr_en) begin
				write_valid = m_write_valid[i];
				write_data = m_write_data[i*DW+:DW];
			end

			if(rd_en) begin
				m_read_valid[i] = read_valid;
				read_ack = m_read_ack[i];
			end
		end
	end
end

endmodule
