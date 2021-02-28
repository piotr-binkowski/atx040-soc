module irqc (
	input clk,
	input rst,

	input [6:0] irq_in,

	output irq_req,
	output [7:0] irq_vec,
	input  irq_ack
);

localparam BASE_VEC = 8'd25;

reg [6:0] irq_d  = 7'd0;
reg [6:0] irq_dd = 7'd0;
reg [6:0] irq_i  = 7'd0;

reg [2:0] irq_no = 3'd0;

integer i;

assign irq_vec = BASE_VEC + irq_no;
assign irq_req = irq_i != 7'd0;

always @(posedge clk) begin
	if (rst) begin
		irq_i   <= 7'd0;
		irq_d   <= 7'd0;
		irq_dd  <= 7'd0;
		irq_no  <= 3'd0;
	end else begin
		irq_d <= irq_in;
		irq_dd <= irq_d;

		for(i = 0; i < 7; i = i+1)
			if((irq_dd[i] == 1'b0) && (irq_d[i] == 1'b1))
				irq_i[i] <= 1'b1;

		for(i = 0; i < 7; i = i+1)
			if(irq_i[i] == 1'b1)
				irq_no  <= i;

		if(irq_req & irq_ack) begin
			irq_i[irq_no] <= 1'b0;
		end
	end
end

endmodule
