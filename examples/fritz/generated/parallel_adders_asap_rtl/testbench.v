`timescale 1ns/1ps
module tb_generated_system;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, start=0, step_enable=0;
  wire busy, done;
  wire [1:0] step_debug;
  reg [7:0] in_A=0;
  reg [7:0] in_B=0;
  reg [7:0] in_C=0;
  reg [7:0] in_D=0;
  wire [7:0] out_X;
  wire [7:0] out_Y;
  wire [7:0] out_Z;
  wire [7:0] out_Q;
  wire [7:0] fu_add_0_out;
  wire [7:0] fu_add_1_out;
  wire [7:0] fu_sub_0_out;
  generated_system dut (.clk(clk), .rst(rst), .start(start), .step_enable(step_enable), .busy(busy), .done(done), .step_debug(step_debug), .in_A(in_A), .in_B(in_B), .in_C(in_C), .in_D(in_D), .out_X(out_X), .out_Y(out_Y), .out_Z(out_Z), .out_Q(out_Q), .fu_add_0_out(fu_add_0_out), .fu_add_1_out(fu_add_1_out), .fu_sub_0_out(fu_sub_0_out));
  initial begin
    repeat (2) @(negedge clk); rst=0;
    // Independent reference vector 0
    @(negedge clk);
    in_A = 8'd2;
    in_B = 8'd3;
    in_C = 8'd4;
    in_D = 8'd5;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 0: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd5) $fatal(1,"Vector 0 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd9) $fatal(1,"Vector 0 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd14) $fatal(1,"Vector 0 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd12) $fatal(1,"Vector 0 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 0: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd5) $fatal(1,"Vector 0: out_X got %0d expected 5", out_X);
    if (out_Y !== 8'd9) $fatal(1,"Vector 0: out_Y got %0d expected 9", out_Y);
    if (out_Z !== 8'd14) $fatal(1,"Vector 0: out_Z got %0d expected 14", out_Z);
    if (out_Q !== 8'd12) $fatal(1,"Vector 0: out_Q got %0d expected 12", out_Q);
    // Independent reference vector 1
    @(negedge clk);
    in_A = 8'd0;
    in_B = 8'd0;
    in_C = 8'd0;
    in_D = 8'd0;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 1: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd0) $fatal(1,"Vector 1 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd0) $fatal(1,"Vector 1 step 0: add_1 mismatch");
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
    if (fu_sub_0_out !== 8'd0) $fatal(1,"Vector 1 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 1: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd0) $fatal(1,"Vector 1: out_X got %0d expected 0", out_X);
    if (out_Y !== 8'd0) $fatal(1,"Vector 1: out_Y got %0d expected 0", out_Y);
    if (out_Z !== 8'd0) $fatal(1,"Vector 1: out_Z got %0d expected 0", out_Z);
    if (out_Q !== 8'd0) $fatal(1,"Vector 1: out_Q got %0d expected 0", out_Q);
    // Independent reference vector 2
    @(negedge clk);
    in_A = 8'd255;
    in_B = 8'd255;
    in_C = 8'd255;
    in_D = 8'd255;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 2: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd254) $fatal(1,"Vector 2 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd254) $fatal(1,"Vector 2 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd252) $fatal(1,"Vector 2 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd253) $fatal(1,"Vector 2 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 2: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd254) $fatal(1,"Vector 2: out_X got %0d expected 254", out_X);
    if (out_Y !== 8'd254) $fatal(1,"Vector 2: out_Y got %0d expected 254", out_Y);
    if (out_Z !== 8'd252) $fatal(1,"Vector 2: out_Z got %0d expected 252", out_Z);
    if (out_Q !== 8'd253) $fatal(1,"Vector 2: out_Q got %0d expected 253", out_Q);
    // Independent reference vector 3
    @(negedge clk);
    in_A = 8'd121;
    in_B = 8'd7;
    in_C = 8'd106;
    in_D = 8'd124;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 3: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd128) $fatal(1,"Vector 3 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd230) $fatal(1,"Vector 3 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd102) $fatal(1,"Vector 3 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd237) $fatal(1,"Vector 3 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 3: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd128) $fatal(1,"Vector 3: out_X got %0d expected 128", out_X);
    if (out_Y !== 8'd230) $fatal(1,"Vector 3: out_Y got %0d expected 230", out_Y);
    if (out_Z !== 8'd102) $fatal(1,"Vector 3: out_Z got %0d expected 102", out_Z);
    if (out_Q !== 8'd237) $fatal(1,"Vector 3: out_Q got %0d expected 237", out_Q);
    // Independent reference vector 4
    @(negedge clk);
    in_A = 8'd189;
    in_B = 8'd208;
    in_C = 8'd204;
    in_D = 8'd8;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 4: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd141) $fatal(1,"Vector 4 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd212) $fatal(1,"Vector 4 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd97) $fatal(1,"Vector 4 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd164) $fatal(1,"Vector 4 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 4: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd141) $fatal(1,"Vector 4: out_X got %0d expected 141", out_X);
    if (out_Y !== 8'd212) $fatal(1,"Vector 4: out_Y got %0d expected 212", out_Y);
    if (out_Z !== 8'd97) $fatal(1,"Vector 4: out_Z got %0d expected 97", out_Z);
    if (out_Q !== 8'd164) $fatal(1,"Vector 4: out_Q got %0d expected 164", out_Q);
    // Independent reference vector 5
    @(negedge clk);
    in_A = 8'd88;
    in_B = 8'd131;
    in_C = 8'd162;
    in_D = 8'd41;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 5: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd219) $fatal(1,"Vector 5 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd203) $fatal(1,"Vector 5 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd166) $fatal(1,"Vector 5 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd78) $fatal(1,"Vector 5 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 5: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd219) $fatal(1,"Vector 5: out_X got %0d expected 219", out_X);
    if (out_Y !== 8'd203) $fatal(1,"Vector 5: out_Y got %0d expected 203", out_Y);
    if (out_Z !== 8'd166) $fatal(1,"Vector 5: out_Z got %0d expected 166", out_Z);
    if (out_Q !== 8'd78) $fatal(1,"Vector 5: out_Q got %0d expected 78", out_Q);
    // Independent reference vector 6
    @(negedge clk);
    in_A = 8'd222;
    in_B = 8'd2;
    in_C = 8'd245;
    in_D = 8'd88;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 6: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd224) $fatal(1,"Vector 6 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd77) $fatal(1,"Vector 6 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd45) $fatal(1,"Vector 6 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd79) $fatal(1,"Vector 6 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 6: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd224) $fatal(1,"Vector 6: out_X got %0d expected 224", out_X);
    if (out_Y !== 8'd77) $fatal(1,"Vector 6: out_Y got %0d expected 77", out_Y);
    if (out_Z !== 8'd45) $fatal(1,"Vector 6: out_Z got %0d expected 45", out_Z);
    if (out_Q !== 8'd79) $fatal(1,"Vector 6: out_Q got %0d expected 79", out_Q);
    // Independent reference vector 7
    @(negedge clk);
    in_A = 8'd24;
    in_B = 8'd156;
    in_C = 8'd159;
    in_D = 8'd225;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 7: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd180) $fatal(1,"Vector 7 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd128) $fatal(1,"Vector 7 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd52) $fatal(1,"Vector 7 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd28) $fatal(1,"Vector 7 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 7: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd180) $fatal(1,"Vector 7: out_X got %0d expected 180", out_X);
    if (out_Y !== 8'd128) $fatal(1,"Vector 7: out_Y got %0d expected 128", out_Y);
    if (out_Z !== 8'd52) $fatal(1,"Vector 7: out_Z got %0d expected 52", out_Z);
    if (out_Q !== 8'd28) $fatal(1,"Vector 7: out_Q got %0d expected 28", out_Q);
    // Independent reference vector 8
    @(negedge clk);
    in_A = 8'd205;
    in_B = 8'd242;
    in_C = 8'd209;
    in_D = 8'd122;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 8: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd191) $fatal(1,"Vector 8 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd75) $fatal(1,"Vector 8 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd10) $fatal(1,"Vector 8 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd61) $fatal(1,"Vector 8 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 8: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd191) $fatal(1,"Vector 8: out_X got %0d expected 191", out_X);
    if (out_Y !== 8'd75) $fatal(1,"Vector 8: out_Y got %0d expected 75", out_Y);
    if (out_Z !== 8'd10) $fatal(1,"Vector 8: out_Z got %0d expected 10", out_Z);
    if (out_Q !== 8'd61) $fatal(1,"Vector 8: out_Q got %0d expected 61", out_Q);
    // Independent reference vector 9
    @(negedge clk);
    in_A = 8'd38;
    in_B = 8'd220;
    in_C = 8'd134;
    in_D = 8'd187;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 9: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd2) $fatal(1,"Vector 9 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd65) $fatal(1,"Vector 9 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd67) $fatal(1,"Vector 9 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd29) $fatal(1,"Vector 9 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 9: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd2) $fatal(1,"Vector 9: out_X got %0d expected 2", out_X);
    if (out_Y !== 8'd65) $fatal(1,"Vector 9: out_Y got %0d expected 65", out_Y);
    if (out_Z !== 8'd67) $fatal(1,"Vector 9: out_Z got %0d expected 67", out_Z);
    if (out_Q !== 8'd29) $fatal(1,"Vector 9: out_Q got %0d expected 29", out_Q);
    // Independent reference vector 10
    @(negedge clk);
    in_A = 8'd61;
    in_B = 8'd230;
    in_C = 8'd48;
    in_D = 8'd161;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 10: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd35) $fatal(1,"Vector 10 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd209) $fatal(1,"Vector 10 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd244) $fatal(1,"Vector 10 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd183) $fatal(1,"Vector 10 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 10: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd35) $fatal(1,"Vector 10: out_X got %0d expected 35", out_X);
    if (out_Y !== 8'd209) $fatal(1,"Vector 10: out_Y got %0d expected 209", out_Y);
    if (out_Z !== 8'd244) $fatal(1,"Vector 10: out_Z got %0d expected 244", out_Z);
    if (out_Q !== 8'd183) $fatal(1,"Vector 10: out_Q got %0d expected 183", out_Q);
    // Independent reference vector 11
    @(negedge clk);
    in_A = 8'd1;
    in_B = 8'd112;
    in_C = 8'd8;
    in_D = 8'd29;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 11: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd113) $fatal(1,"Vector 11 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd37) $fatal(1,"Vector 11 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd150) $fatal(1,"Vector 11 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd149) $fatal(1,"Vector 11 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 11: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd113) $fatal(1,"Vector 11: out_X got %0d expected 113", out_X);
    if (out_Y !== 8'd37) $fatal(1,"Vector 11: out_Y got %0d expected 37", out_Y);
    if (out_Z !== 8'd150) $fatal(1,"Vector 11: out_Z got %0d expected 150", out_Z);
    if (out_Q !== 8'd149) $fatal(1,"Vector 11: out_Q got %0d expected 149", out_Q);
    // Independent reference vector 12
    @(negedge clk);
    in_A = 8'd179;
    in_B = 8'd62;
    in_C = 8'd136;
    in_D = 8'd91;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 12: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd241) $fatal(1,"Vector 12 step 0: add_0 mismatch");
    if (fu_add_1_out !== 8'd227) $fatal(1,"Vector 12 step 0: add_1 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd212) $fatal(1,"Vector 12 step 1: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd33) $fatal(1,"Vector 12 step 2: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 12: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd241) $fatal(1,"Vector 12: out_X got %0d expected 241", out_X);
    if (out_Y !== 8'd227) $fatal(1,"Vector 12: out_Y got %0d expected 227", out_Y);
    if (out_Z !== 8'd212) $fatal(1,"Vector 12: out_Z got %0d expected 212", out_Z);
    if (out_Q !== 8'd33) $fatal(1,"Vector 12: out_Q got %0d expected 33", out_Q);
    $display("PASS: all generated test vectors passed");
$finish;
  end
endmodule
