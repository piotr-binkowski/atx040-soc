module wb_uart(clk_i, rst_i, cyc_i, stb_i, adr_i, we_i, dat_i, sel_i, ack_o, dat_o, txd, rxd);

parameter  DIV  = 861;
parameter  CW   = $clog2(DIV);

localparam AW   = 2;
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

output [DW-1:0] dat_o;
output reg ack_o;

output reg txd;
input rxd;

reg [CW-1:0] cnt = 0;
reg pulse = 1'b0;

always @(posedge clk_i) begin
	if(cnt < DIV) begin
		cnt   <= cnt + 1;
		pulse <= 0;
	end else begin
		cnt   <= 0;
		pulse <= 1;
	end
end

assign dat_o = 0;

always @(posedge clk_i)
	if(ack_o)
		ack_o <= 1'b0; 
	else
		ack_o <= stb_i;

wire tx_empty;
wire [7:0] tx_data;
reg tx_rd;

fifo #(
	.SIZE(64),
	.DW(8)
) fifo_tx_i (
	.clk(clk_i),
	.rst(rst_i),
	.wr(ack_o),
	.wdata(dat_i[31:24]),
	.rd(tx_rd),
	.rdata(tx_data),
	.empty(tx_empty),
	.full()
);

reg [3:0] tx_cnt = 4'd10;
reg [9:0] tx_reg;

always @(posedge clk_i) begin
	tx_rd <= 1'b0;
	if (tx_cnt == 4'd10) begin
		txd    <= 1'b1;
		if (!tx_empty) begin
			tx_rd  <= 1'b1;
			tx_cnt <= 4'd0;
			tx_reg <= {1'b1, tx_data, 1'b0};
		end
	end else if (pulse == 1'b1) begin
		txd    <= tx_reg[0];
		tx_reg <= {1'b1, tx_reg[9:1]};
		tx_cnt <= tx_cnt + 1'b1;
	end
end

endmodule
