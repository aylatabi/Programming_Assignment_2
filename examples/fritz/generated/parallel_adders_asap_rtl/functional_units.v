// Standalone one-cycle combinational reference units. Swap with Ayla's units
// after matching widths, signedness, and combinational latency.
module pa2_add #(parameter WIDTH=16)(input [WIDTH-1:0] a,b, output [WIDTH-1:0] y);
    assign y = a + b;
endmodule
module pa2_sub #(parameter WIDTH=16)(input [WIDTH-1:0] a,b, output [WIDTH-1:0] y);
    assign y = a - b;
endmodule
module pa2_mul #(parameter WIDTH=16)(input [WIDTH-1:0] a,b, output [WIDTH-1:0] y);
    assign y = a * b; // truncates modulo 2**WIDTH
endmodule
