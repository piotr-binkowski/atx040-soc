module oreg(input clk, output pad, input o);

wire o_q;

OBUF buf_i (
	.I(o_q),
	.O(pad)
);

ODDR2 #(
	.SRTYPE("ASYNC"),
	.DDR_ALIGNMENT("C0")
) o_ddr_i (
	.C0(clk),
	.C1(~clk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.D0(o),
	.D1(o),
	.Q(o_q)
);

endmodule

module ireg(input clk, input pad, output i);

wire i_q;

IBUF buf_i (
	.I(pad),
	.O(i_q)
);

IDDR2 #(
	.SRTYPE("ASYNC"),
	.DDR_ALIGNMENT("C0")
) i_ddr_i (
	.C0(clk),
	.C1(~clk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.D(i_q),
	.Q0(i),
	.Q1()
);

endmodule

module ioreg(input clk, inout pad, input o, output i, input t);

wire t_q, i_q, o_q;

IOBUF buf_i (
	.T(t_q),
	.I(o_q),
	.O(i_q),
	.IO(pad)
);

ODDR2 #(
	.SRTYPE("ASYNC"),
	.DDR_ALIGNMENT("C0")
) t_ddr_i (
	.C0(clk),
	.C1(~clk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.D0(t),
	.D1(t),
	.Q(t_q)
);

ODDR2 #(
	.SRTYPE("ASYNC"),
	.DDR_ALIGNMENT("C0")
) o_ddr_i (
	.C0(clk),
	.C1(~clk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.D0(o),
	.D1(o),
	.Q(o_q)
);

IDDR2 #(
	.SRTYPE("ASYNC"),
	.DDR_ALIGNMENT("C0")
) i_ddr_i (
	.C0(clk),
	.C1(~clk),
	.CE(1'b1),
	.R(1'b0),
	.S(1'b0),
	.D(i_q),
	.Q0(i),
	.Q1()
);

endmodule
