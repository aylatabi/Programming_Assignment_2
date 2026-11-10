// Generated Nexys4 DDR top level. Constraints: rtl/nexys4ddr.xdc.
// Controls: SW[7:0] value, BTNL/BTNR pick input, BTNU load, BTND start,
// BTNC step one cycle, CPU_RESETN reset, SW[15:10] choose what to display.
// Display: [7:6] selection  [5:4] cycle  [3:0] value (decimal).
// For ~3 s after BTNL/BTNR/BTNU: [7:6] input box  [5:4] blank  [3:0] its stored value.
// SW[15:10] selection list:
//    0: fu_add_0_out
//    1: fu_sub_0_out
//    2: out_X
//    3: out_Y
//    4: out_Z
//    5: out_Q
//    6: in_A
//    7: in_B
//    8: in_C
//    9: in_D
// Inputs (BTNL/BTNR order, index on LED[12:8]):
//    0: in_A
//    1: in_B
//    2: in_C
//    3: in_D
module fpga_top #(
    parameter DEBOUNCE_BITS = 20,
    parameter REFRESH_BITS = 17,
    parameter HOLD_BITS = 28        // input view lasts 2**28 clocks, about 2.7 s
) (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC, BTNU, BTNL, BTNR, BTND,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [6:0]  SEG,
    output wire        DP,
    output wire [7:0]  AN
);
  wire clk = CLK100MHZ;

  // Reset: CPU_RESETN is active low; synchronise it to the clock.
  reg [1:0] rst_sync = 2'b11;
  always @(posedge clk) rst_sync <= {rst_sync[0], ~CPU_RESETN};
  wire rst = rst_sync[1];

  wire step_p, load_p, prev_p, next_p, start_p;
  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_step  (.clk(clk), .rst(rst), .btn(BTNC), .pulse(step_p));
  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_load  (.clk(clk), .rst(rst), .btn(BTNU), .pulse(load_p));
  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_prev  (.clk(clk), .rst(rst), .btn(BTNL), .pulse(prev_p));
  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_next  (.clk(clk), .rst(rst), .btn(BTNR), .pulse(next_p));
  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_start (.clk(clk), .rst(rst), .btn(BTND), .pulse(start_p));

  wire [7:0] sw_value = SW[7:0];

  // Input values loaded from the switches
  reg [1:0] in_sel;
  reg [7:0] val_in_A;
  reg [7:0] val_in_B;
  reg [7:0] val_in_C;
  reg [7:0] val_in_D;
  always @(posedge clk) begin
    if (rst) begin
      in_sel <= 2'd0;
      val_in_A <= 8'd0;
      val_in_B <= 8'd0;
      val_in_C <= 8'd0;
      val_in_D <= 8'd0;
    end else begin
      if (next_p) in_sel <= (in_sel == 2'd3) ? 2'd0 : in_sel + 1'b1;
      else if (prev_p) in_sel <= (in_sel == 2'd0) ? 2'd3 : in_sel - 1'b1;
      if (load_p) begin
        case (in_sel)
          2'd0: val_in_A <= sw_value;
          2'd1: val_in_B <= sw_value;
          2'd2: val_in_C <= sw_value;
          2'd3: val_in_D <= sw_value;
          default: ;
        endcase
      end
    end
  end

  reg [7:0] in_sel_value;
  always @* begin
    case (in_sel)
      2'd0: in_sel_value = val_in_A;
      2'd1: in_sel_value = val_in_B;
      2'd2: in_sel_value = val_in_C;
      2'd3: in_sel_value = val_in_D;
      default: in_sel_value = 8'd0;
    endcase
  end

  wire busy, done;
  wire [1:0] step;
  wire [7:0] out_X;
  wire [7:0] out_Y;
  wire [7:0] out_Z;
  wire [7:0] out_Q;
  wire [7:0] fu_add_0_out;
  wire [7:0] fu_sub_0_out;
  generated_system sys (
    .clk(clk),
    .rst(rst),
    .start(start_p),
    .step_enable(step_p),
    .busy(busy),
    .done(done),
    .step_debug(step),
    .in_A(val_in_A),
    .in_B(val_in_B),
    .in_C(val_in_C),
    .in_D(val_in_D),
    .out_X(out_X),
    .out_Y(out_Y),
    .out_Z(out_Z),
    .out_Q(out_Q),
    .fu_add_0_out(fu_add_0_out),
    .fu_sub_0_out(fu_sub_0_out)
  );

  wire [5:0] show_sel = SW[15:10];
  reg [7:0] shown;
  reg shown_valid;
  always @* begin
    shown_valid = 1'b1;
    case (show_sel)
      6'd0: shown = fu_add_0_out;
      6'd1: shown = fu_sub_0_out;
      6'd2: shown = out_X;
      6'd3: shown = out_Y;
      6'd4: shown = out_Z;
      6'd5: shown = out_Q;
      6'd6: shown = val_in_A;
      6'd7: shown = val_in_B;
      6'd8: shown = val_in_C;
      6'd9: shown = val_in_D;
      default: begin shown = 8'd0; shown_valid = 1'b0; end
    endcase
  end

  // Cycle number on the display: 1-based while running, last cycle when done.
  wire [7:0] cycle_no = busy ? {{(8-2){1'b0}}, step} + 8'd1 :
                        done ? 8'd4 : 8'd0;

  // Input view: after BTNL/BTNR/BTNU, show the input box and its value for a while.
  reg [HOLD_BITS-1:0] hold;
  always @(posedge clk) begin
    if (rst) hold <= {HOLD_BITS{1'b0}};
    else if (prev_p | next_p | load_p) hold <= {HOLD_BITS{1'b1}};
    else if (hold != {HOLD_BITS{1'b0}}) hold <= hold - 1'b1;
  end
  wire input_view = |hold;
  wire [5:0] in_sel_wide = {4'd0, in_sel};
  wire [5:0] disp_sel = input_view ? in_sel_wide : show_sel;
  wire disp_valid = input_view | shown_valid;

  wire [31:0] v = input_view ? in_sel_value : shown;
  wire [3:0] v0 = v % 10;
  wire [3:0] v1 = (v / 10) % 10;
  wire [3:0] v2 = (v / 100) % 10;
  wire [3:0] v3 = (v / 1000) % 10;
  wire [3:0] c0 = cycle_no % 10;
  wire [3:0] c1 = (cycle_no / 10) % 10;
  wire [3:0] s0 = disp_sel % 10;
  wire [3:0] s1 = disp_sel / 10;

  pa2_sevenseg #(.REFRESH_BITS(REFRESH_BITS)) disp (
    .clk(clk), .rst(rst),
    .digits({s1, s0, c1, c0, v3, v2, v1, v0}),
    // Hide the cycle in input view, value digits when nothing is selected,
    // and leading zeros of the value.
    .blank({2'b00, input_view, input_view,
            ~disp_valid | (v < 1000), ~disp_valid | (v < 100),
            ~disp_valid | (v < 10), ~disp_valid}),
    .seg(SEG), .an(AN));
  assign DP = 1'b1;

  assign LED[7:0]  = in_sel_value[7:0];
  assign LED[12:8] = {3'd0, in_sel};
  assign LED[13]   = busy;
  assign LED[14]   = done;
  assign LED[15]   = ~shown_valid;
endmodule
