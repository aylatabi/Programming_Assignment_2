`timescale 1ns/1ps
// Board-level test for the professor example (X=A+B, Y=X+A, Z=X-B, Q=B*Z), A=3 B=2.
// Run: python -m pytest tests/board  (generates the RTL, then runs this in Icarus).
module tb_fpga_top;
  reg clk = 0;
  always #5 clk = ~clk;

  reg CPU_RESETN = 0;
  reg BTNC = 0, BTNU = 0, BTNL = 0, BTNR = 0, BTND = 0;
  reg [15:0] SW = 0;
  wire [15:0] LED;
  wire [6:0] SEG;
  wire DP;
  wire [7:0] AN;

  fpga_top #(.DEBOUNCE_BITS(3), .REFRESH_BITS(2), .HOLD_BITS(4)) dut (
    .CLK100MHZ(clk), .CPU_RESETN(CPU_RESETN),
    .BTNC(BTNC), .BTNU(BTNU), .BTNL(BTNL), .BTNR(BTNR), .BTND(BTND),
    .SW(SW), .LED(LED), .SEG(SEG), .DP(DP), .AN(AN));

  integer errors = 0;

  // Hold a button long enough to pass the debouncer, then release it.
  task press(input integer which);
    begin
      case (which) 0: BTNC = 1; 1: BTNU = 1; 2: BTNL = 1; 3: BTNR = 1; 4: BTND = 1; endcase
      repeat (30) @(posedge clk);
      BTNC = 0; BTNU = 0; BTNL = 0; BTNR = 0; BTND = 0;
      repeat (30) @(posedge clk);
    end
  endtask
  localparam C = 0, U = 1, L = 2, R = 3, D = 4;

  task check(input [8*48-1:0] what, input integer got, input integer want);
    if (got !== want) begin
      $display("FAIL %0s: got %0d, want %0d", what, got, want);
      errors = errors + 1;
    end else
      $display("ok   %0s = %0d", what, got);
  endtask

  // Decode one active-low 7-segment pattern to a digit (15 = blank/unknown).
  function integer seg_digit(input [6:0] s);
    case (s)
      7'b1000000: seg_digit = 0;  7'b1111001: seg_digit = 1;
      7'b0100100: seg_digit = 2;  7'b0110000: seg_digit = 3;
      7'b0011001: seg_digit = 4;  7'b0010010: seg_digit = 5;
      7'b0000010: seg_digit = 6;  7'b1111000: seg_digit = 7;
      7'b0000000: seg_digit = 8;  7'b0010000: seg_digit = 9;
      default:    seg_digit = 15;
    endcase
  endfunction

  // Watch the multiplexed display for a full refresh and rebuild all 8 digits.
  // Returns digits as decimal number per group; blank digits read as 0.
  integer dig [0:7];
  integer i, k;
  task read_display(output integer sel, output integer cyc, output integer val, output integer blanks);
    begin
      for (i = 0; i < 8; i = i + 1) dig[i] = -1;
      repeat (8 * 8) begin
        @(posedge clk); #1;
        for (k = 0; k < 8; k = k + 1)
          if (AN[k] == 1'b0) dig[k] = seg_digit(SEG);
      end
      blanks = 0;
      for (i = 0; i < 8; i = i + 1) if (dig[i] == -1) begin blanks = blanks + 1; dig[i] = 0; end
      sel = dig[7] * 10 + dig[6];
      cyc = dig[5] * 10 + dig[4];
      val = dig[3] * 1000 + dig[2] * 100 + dig[1] * 10 + dig[0];
    end
  endtask

  integer sel, cyc, val, blanks;

  initial begin
    repeat (5) @(posedge clk);
    CPU_RESETN = 1;
    repeat (5) @(posedge clk);

    // Load A = 3 (input 0), then B = 2 (input 1).
    SW[7:0] = 3; press(U);
    check("LED index after load A", LED[12:8], 0);
    check("LED value after load A", LED[7:0], 3);
    press(R);
    SW[7:0] = 2; press(U);
    check("LED index after load B", LED[12:8], 1);
    check("LED value after load B", LED[7:0], 2);
    press(R);                                   // wraps back to A
    check("LED index wraps to A", LED[12:8], 0);
    check("LED shows A again", LED[7:0], 3);
    press(L);                                   // wraps back to B
    check("BTNL wraps to B", LED[12:8], 1);

    // Show input A on the display (selection 7) before starting.
    SW[15:10] = 7;
    read_display(sel, cyc, val, blanks);
    check("display selection", sel, 7);
    check("display cycle before start", cyc, 0);
    check("display value of A", val, 3);

    // Start and step through the 3 cycles, watching the adder (selection 0).
    press(D);
    check("busy after start", LED[13], 1);
    SW[15:10] = 0;
    read_display(sel, cyc, val, blanks);
    check("cycle 1 shown", cyc, 1);
    check("adder in cycle 1 (A+B)", val, 5);
    press(C);
    read_display(sel, cyc, val, blanks);
    check("cycle 2 shown", cyc, 2);
    check("adder in cycle 2 (X+A)", val, 8);
    SW[15:10] = 1;
    read_display(sel, cyc, val, blanks);
    check("subtractor in cycle 2 (X-B)", val, 3);
    press(C);
    SW[15:10] = 2;
    read_display(sel, cyc, val, blanks);
    check("cycle 3 shown", cyc, 3);
    check("multiplier in cycle 3 (B*Z)", val, 6);
    press(C);
    check("done after last step", LED[14], 1);
    check("not busy after last step", LED[13], 0);

    // Final outputs X, Y, Z, Q are selections 3..6.
    SW[15:10] = 3; read_display(sel, cyc, val, blanks); check("out X", val, 5);
    SW[15:10] = 4; read_display(sel, cyc, val, blanks); check("out Y", val, 8);
    SW[15:10] = 5; read_display(sel, cyc, val, blanks); check("out Z", val, 3);
    SW[15:10] = 6; read_display(sel, cyc, val, blanks); check("out Q", val, 6);
    check("cycle stays at 3 when done", cyc, 3);

    // A selection past the end lights LED15 and blanks the value digits.
    SW[15:10] = 40;
    read_display(sel, cyc, val, blanks);
    check("LED15 on invalid selection", LED[15], 1);
    check("blank digits on invalid selection", blanks, 4);

    // Extra steps after done change nothing.
    press(C);
    SW[15:10] = 6; read_display(sel, cyc, val, blanks); check("out Q after extra step", val, 6);

    // Restart with new inputs without reset: A=10, B=4 -> Q = 4*(14-4) = 40.
    press(L);                                   // index 0 = A
    SW[7:0] = 10; press(U);
    press(R);
    SW[7:0] = 4; press(U);
    press(D); press(C); press(C); press(C);
    SW[15:10] = 6; read_display(sel, cyc, val, blanks); check("restart: out Q", val, 40);
    SW[15:10] = 4; read_display(sel, cyc, val, blanks); check("restart: out Y", val, 24);

    // Input view: BTNL goes back to box 0 (A = 10) and the display shows
    // the box number and its value, with the cycle digits blank.
    BTNL = 1;
    for (i = 0; i < 100 && !dut.input_view; i = i + 1) @(posedge clk);
    #1;
    check("input view starts on BTNL", dut.input_view, 1);
    check("input view box number", dut.disp_sel, 0);
    check("input view value of A", dut.v, 10);
    check("input view blanks cycle digits", dut.disp.blank[5:4], 3);
    BTNL = 0;
    repeat (60) @(posedge clk);
    check("normal view returns", dut.input_view, 0);
    check("normal view shows Y again", dut.v, 24);

    // Reset clears everything.
    CPU_RESETN = 0; repeat (5) @(posedge clk); CPU_RESETN = 1; repeat (5) @(posedge clk);
    check("reset clears done", LED[14], 0);
    check("reset clears input", LED[7:0], 0);

    if (errors == 0) $display("PASS: fpga_top board test");
    else $display("FAIL: %0d check(s) failed", errors);
    $finish;
  end
endmodule
