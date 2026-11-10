// Board helpers used by the generated fpga_top (Nexys4 DDR, 100 MHz clock).

// Debounced push button: one clock-wide pulse each time the button is pressed.
// The input must be stable for 2**BITS clocks (2**20 at 100 MHz is about 10 ms).
module pa2_debounce #(parameter BITS = 20) (
    input  wire clk,
    input  wire rst,
    input  wire btn,
    output reg  pulse
);
    reg [1:0] sync;
    reg stable;
    reg [BITS-1:0] count;
    always @(posedge clk) begin
        sync  <= {sync[0], btn};
        pulse <= 1'b0;
        if (rst) begin
            stable <= 1'b0;
            count  <= {BITS{1'b0}};
        end else if (sync[1] == stable) begin
            count <= {BITS{1'b0}};
        end else begin
            count <= count + 1'b1;
            if (&count) begin
                stable <= sync[1];
                pulse  <= sync[1];      // pulse on press only, not on release
            end
        end
    end
endmodule

// 8-digit multiplexed 7-segment driver. digits[4*i+3:4*i] is shown on digit i
// (digit 0 is the rightmost). A 1 in blank[i] turns digit i off.
// Segments and anodes are active low. seg = {g,f,e,d,c,b,a}.
module pa2_sevenseg #(parameter REFRESH_BITS = 17) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] digits,
    input  wire [7:0]  blank,
    output reg  [6:0]  seg,
    output reg  [7:0]  an
);
    reg [REFRESH_BITS+2:0] count;
    always @(posedge clk)
        count <= rst ? {(REFRESH_BITS+3){1'b0}} : count + 1'b1;

    wire [2:0] idx = count[REFRESH_BITS+2:REFRESH_BITS];
    wire [3:0] nibble = digits[idx*4 +: 4];

    always @* begin
        an = 8'hFF;
        if (!blank[idx]) an[idx] = 1'b0;
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            default: seg = 7'b0001110;  // F
        endcase
    end
endmodule
