module wb_uart (
	input  wire clk,

	output wire txd,

	input  wire cyc_i,
	input  wire stb_i,
	output wire ack_o,
	input  wire [31:0] dat_i,
	input  wire we_o
);

reg [9:0] cnt = 10'd0;

reg pulse = 1'b0;

always @(posedge clk) begin
	if(cnt < 861) begin
		cnt   <= cnt + 1;
		pulse <= 0;
	end else begin
		cnt   <= 0;
		pulse <= 1;
	end
end

reg [9:0] tx = 10'b1111111111;

assign ack_o = stb_i;

reg txd_o;
assign txd = txd_o;

always @(posedge clk) begin
	if(stb_i == 1'b1 && we_o == 1'b1) begin
		txd_o <= 1'b1;
		tx    <= {1'b0, dat_i[31:24], 1'b1};
	end else if (pulse == 1'b1) begin
		txd_o <= tx[9];
		tx    <= {tx[8:0], 1'b1};
	end
end

endmodule
