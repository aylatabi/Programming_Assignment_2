`timescale 1ns/1ps
module tb_generated_system;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, start=0, step_enable=0;
  wire busy, done;
  wire [1:0] step_debug;
  reg [7:0] in_B=0;
  reg [7:0] in_C=0;
  reg [7:0] in_D=0;
  reg [7:0] in_E=0;
  wire [7:0] out_A;
  wire [7:0] out_P;
  wire [7:0] out_R;
  wire [7:0] fu_add_0_out;
  wire [7:0] fu_sub_0_out;
  wire [7:0] fu_mul_0_out;
  generated_system dut (.clk(clk), .rst(rst), .start(start), .step_enable(step_enable), .busy(busy), .done(done), .step_debug(step_debug), .in_B(in_B), .in_C(in_C), .in_D(in_D), .in_E(in_E), .out_A(out_A), .out_P(out_P), .out_R(out_R), .fu_add_0_out(fu_add_0_out), .fu_sub_0_out(fu_sub_0_out), .fu_mul_0_out(fu_mul_0_out));
  initial begin
    repeat (2) @(negedge clk); rst=0;
    // Independent reference vector 0
    @(negedge clk);
    in_B = 8'd2;
    in_C = 8'd3;
    in_D = 8'd4;
    in_E = 8'd2;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 0: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd5) $fatal(1,"Vector 0 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd9) $fatal(1,"Vector 0 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd18) $fatal(1,"Vector 0 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd15) $fatal(1,"Vector 0 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 0: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd9) $fatal(1,"Vector 0: out_A got %0d expected 9", out_A);
    if (out_P !== 8'd18) $fatal(1,"Vector 0: out_P got %0d expected 18", out_P);
    if (out_R !== 8'd15) $fatal(1,"Vector 0: out_R got %0d expected 15", out_R);
    // Independent reference vector 1
    @(negedge clk);
    in_B = 8'd0;
    in_C = 8'd0;
    in_D = 8'd0;
    in_E = 8'd0;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 1: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd0) $fatal(1,"Vector 1 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 1: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 1: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd0) $fatal(1,"Vector 1 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 1: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 1: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd0) $fatal(1,"Vector 1 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 1: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 1: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd0) $fatal(1,"Vector 1 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 1: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd0) $fatal(1,"Vector 1: out_A got %0d expected 0", out_A);
    if (out_P !== 8'd0) $fatal(1,"Vector 1: out_P got %0d expected 0", out_P);
    if (out_R !== 8'd0) $fatal(1,"Vector 1: out_R got %0d expected 0", out_R);
    // Independent reference vector 2
    @(negedge clk);
    in_B = 8'd255;
    in_C = 8'd255;
    in_D = 8'd255;
    in_E = 8'd255;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 2: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd254) $fatal(1,"Vector 2 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd253) $fatal(1,"Vector 2 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd3) $fatal(1,"Vector 2 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd4) $fatal(1,"Vector 2 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 2: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd253) $fatal(1,"Vector 2: out_A got %0d expected 253", out_A);
    if (out_P !== 8'd3) $fatal(1,"Vector 2: out_P got %0d expected 3", out_P);
    if (out_R !== 8'd4) $fatal(1,"Vector 2: out_R got %0d expected 4", out_R);
    // Independent reference vector 3
    @(negedge clk);
    in_B = 8'd121;
    in_C = 8'd7;
    in_D = 8'd106;
    in_E = 8'd124;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 3: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd128) $fatal(1,"Vector 3 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd234) $fatal(1,"Vector 3 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd88) $fatal(1,"Vector 3 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd81) $fatal(1,"Vector 3 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 3: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd234) $fatal(1,"Vector 3: out_A got %0d expected 234", out_A);
    if (out_P !== 8'd88) $fatal(1,"Vector 3: out_P got %0d expected 88", out_P);
    if (out_R !== 8'd81) $fatal(1,"Vector 3: out_R got %0d expected 81", out_R);
    // Independent reference vector 4
    @(negedge clk);
    in_B = 8'd189;
    in_C = 8'd208;
    in_D = 8'd204;
    in_E = 8'd8;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 4: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd141) $fatal(1,"Vector 4 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd89) $fatal(1,"Vector 4 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd200) $fatal(1,"Vector 4 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd248) $fatal(1,"Vector 4 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 4: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd89) $fatal(1,"Vector 4: out_A got %0d expected 89", out_A);
    if (out_P !== 8'd200) $fatal(1,"Vector 4: out_P got %0d expected 200", out_P);
    if (out_R !== 8'd248) $fatal(1,"Vector 4: out_R got %0d expected 248", out_R);
    // Independent reference vector 5
    @(negedge clk);
    in_B = 8'd88;
    in_C = 8'd131;
    in_D = 8'd162;
    in_E = 8'd41;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 5: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd219) $fatal(1,"Vector 5 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd125) $fatal(1,"Vector 5 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd5) $fatal(1,"Vector 5 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd130) $fatal(1,"Vector 5 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 5: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd125) $fatal(1,"Vector 5: out_A got %0d expected 125", out_A);
    if (out_P !== 8'd5) $fatal(1,"Vector 5: out_P got %0d expected 5", out_P);
    if (out_R !== 8'd130) $fatal(1,"Vector 5: out_R got %0d expected 130", out_R);
    // Independent reference vector 6
    @(negedge clk);
    in_B = 8'd222;
    in_C = 8'd2;
    in_D = 8'd245;
    in_E = 8'd88;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 6: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd224) $fatal(1,"Vector 6 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd213) $fatal(1,"Vector 6 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd56) $fatal(1,"Vector 6 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd54) $fatal(1,"Vector 6 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 6: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd213) $fatal(1,"Vector 6: out_A got %0d expected 213", out_A);
    if (out_P !== 8'd56) $fatal(1,"Vector 6: out_P got %0d expected 56", out_P);
    if (out_R !== 8'd54) $fatal(1,"Vector 6: out_R got %0d expected 54", out_R);
    // Independent reference vector 7
    @(negedge clk);
    in_B = 8'd24;
    in_C = 8'd156;
    in_D = 8'd159;
    in_E = 8'd225;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 7: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd180) $fatal(1,"Vector 7 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd83) $fatal(1,"Vector 7 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd243) $fatal(1,"Vector 7 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd87) $fatal(1,"Vector 7 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 7: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd83) $fatal(1,"Vector 7: out_A got %0d expected 83", out_A);
    if (out_P !== 8'd243) $fatal(1,"Vector 7: out_P got %0d expected 243", out_P);
    if (out_R !== 8'd87) $fatal(1,"Vector 7: out_R got %0d expected 87", out_R);
    // Independent reference vector 8
    @(negedge clk);
    in_B = 8'd205;
    in_C = 8'd242;
    in_D = 8'd209;
    in_E = 8'd122;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 8: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd191) $fatal(1,"Vector 8 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd144) $fatal(1,"Vector 8 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd160) $fatal(1,"Vector 8 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd174) $fatal(1,"Vector 8 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 8: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd144) $fatal(1,"Vector 8: out_A got %0d expected 144", out_A);
    if (out_P !== 8'd160) $fatal(1,"Vector 8: out_P got %0d expected 160", out_P);
    if (out_R !== 8'd174) $fatal(1,"Vector 8: out_R got %0d expected 174", out_R);
    // Independent reference vector 9
    @(negedge clk);
    in_B = 8'd38;
    in_C = 8'd220;
    in_D = 8'd134;
    in_E = 8'd187;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 9: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd2) $fatal(1,"Vector 9 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd136) $fatal(1,"Vector 9 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd88) $fatal(1,"Vector 9 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd124) $fatal(1,"Vector 9 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 9: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd136) $fatal(1,"Vector 9: out_A got %0d expected 136", out_A);
    if (out_P !== 8'd88) $fatal(1,"Vector 9: out_P got %0d expected 88", out_P);
    if (out_R !== 8'd124) $fatal(1,"Vector 9: out_R got %0d expected 124", out_R);
    // Independent reference vector 10
    @(negedge clk);
    in_B = 8'd61;
    in_C = 8'd230;
    in_D = 8'd48;
    in_E = 8'd161;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 10: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd35) $fatal(1,"Vector 10 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd83) $fatal(1,"Vector 10 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd51) $fatal(1,"Vector 10 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd77) $fatal(1,"Vector 10 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 10: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd83) $fatal(1,"Vector 10: out_A got %0d expected 83", out_A);
    if (out_P !== 8'd51) $fatal(1,"Vector 10: out_P got %0d expected 51", out_P);
    if (out_R !== 8'd77) $fatal(1,"Vector 10: out_R got %0d expected 77", out_R);
    // Independent reference vector 11
    @(negedge clk);
    in_B = 8'd1;
    in_C = 8'd112;
    in_D = 8'd8;
    in_E = 8'd29;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 11: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd113) $fatal(1,"Vector 11 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd121) $fatal(1,"Vector 11 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd181) $fatal(1,"Vector 11 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd69) $fatal(1,"Vector 11 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 11: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd121) $fatal(1,"Vector 11: out_A got %0d expected 121", out_A);
    if (out_P !== 8'd181) $fatal(1,"Vector 11: out_P got %0d expected 181", out_P);
    if (out_R !== 8'd69) $fatal(1,"Vector 11: out_R got %0d expected 69", out_R);
    // Independent reference vector 12
    @(negedge clk);
    in_B = 8'd179;
    in_C = 8'd62;
    in_D = 8'd136;
    in_E = 8'd91;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 12: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd241) $fatal(1,"Vector 12 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd121) $fatal(1,"Vector 12 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_mul_0_out !== 8'd3) $fatal(1,"Vector 12 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd3) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd3) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 4; step counter 3
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd197) $fatal(1,"Vector 12 step 3: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 12: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_A !== 8'd121) $fatal(1,"Vector 12: out_A got %0d expected 121", out_A);
    if (out_P !== 8'd3) $fatal(1,"Vector 12: out_P got %0d expected 3", out_P);
    if (out_R !== 8'd197) $fatal(1,"Vector 12: out_R got %0d expected 197", out_R);
    $display("PASS: all generated test vectors passed");
$finish;
  end
endmodule
