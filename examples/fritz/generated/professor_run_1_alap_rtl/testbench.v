`timescale 1ns/1ps
module tb_generated_system;
  reg clk=0; always #5 clk=~clk;
  reg rst=1, start=0, step_enable=0;
  wire busy, done;
  wire [1:0] step_debug;
  reg [7:0] in_A=0;
  reg [7:0] in_B=0;
  wire [7:0] out_X;
  wire [7:0] out_Y;
  wire [7:0] out_Z;
  wire [7:0] out_Q;
  wire [7:0] fu_add_0_out;
  wire [7:0] fu_sub_0_out;
  wire [7:0] fu_mul_0_out;
  generated_system dut (.clk(clk), .rst(rst), .start(start), .step_enable(step_enable), .busy(busy), .done(done), .step_debug(step_debug), .in_A(in_A), .in_B(in_B), .out_X(out_X), .out_Y(out_Y), .out_Z(out_Z), .out_Q(out_Q), .fu_add_0_out(fu_add_0_out), .fu_sub_0_out(fu_sub_0_out), .fu_mul_0_out(fu_mul_0_out));
  initial begin
    repeat (2) @(negedge clk); rst=0;
    // Independent reference vector 0
    @(negedge clk);
    in_A = 8'd3;
    in_B = 8'd2;
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
    if (fu_sub_0_out !== 8'd3) $fatal(1,"Vector 0 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 0: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 0: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd8) $fatal(1,"Vector 0 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd6) $fatal(1,"Vector 0 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 0: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd5) $fatal(1,"Vector 0: out_X got %0d expected 5", out_X);
    if (out_Y !== 8'd8) $fatal(1,"Vector 0: out_Y got %0d expected 8", out_Y);
    if (out_Z !== 8'd3) $fatal(1,"Vector 0: out_Z got %0d expected 3", out_Z);
    if (out_Q !== 8'd6) $fatal(1,"Vector 0: out_Q got %0d expected 6", out_Q);
    // Independent reference vector 1
    @(negedge clk);
    in_A = 8'd0;
    in_B = 8'd0;
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
    if (fu_sub_0_out !== 8'd0) $fatal(1,"Vector 1 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 1: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 1: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd0) $fatal(1,"Vector 1 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd0) $fatal(1,"Vector 1 step 2: mul_0 mismatch");
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
    if (fu_sub_0_out !== 8'd255) $fatal(1,"Vector 2 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 2: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 2: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd253) $fatal(1,"Vector 2 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd1) $fatal(1,"Vector 2 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 2: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd254) $fatal(1,"Vector 2: out_X got %0d expected 254", out_X);
    if (out_Y !== 8'd253) $fatal(1,"Vector 2: out_Y got %0d expected 253", out_Y);
    if (out_Z !== 8'd255) $fatal(1,"Vector 2: out_Z got %0d expected 255", out_Z);
    if (out_Q !== 8'd1) $fatal(1,"Vector 2: out_Q got %0d expected 1", out_Q);
    // Independent reference vector 3
    @(negedge clk);
    in_A = 8'd121;
    in_B = 8'd7;
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
    if (fu_sub_0_out !== 8'd121) $fatal(1,"Vector 3 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 3: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 3: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd249) $fatal(1,"Vector 3 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd79) $fatal(1,"Vector 3 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 3: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd128) $fatal(1,"Vector 3: out_X got %0d expected 128", out_X);
    if (out_Y !== 8'd249) $fatal(1,"Vector 3: out_Y got %0d expected 249", out_Y);
    if (out_Z !== 8'd121) $fatal(1,"Vector 3: out_Z got %0d expected 121", out_Z);
    if (out_Q !== 8'd79) $fatal(1,"Vector 3: out_Q got %0d expected 79", out_Q);
    // Independent reference vector 4
    @(negedge clk);
    in_A = 8'd106;
    in_B = 8'd124;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 4: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd230) $fatal(1,"Vector 4 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd106) $fatal(1,"Vector 4 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 4: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 4: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd80) $fatal(1,"Vector 4 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd88) $fatal(1,"Vector 4 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 4: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd230) $fatal(1,"Vector 4: out_X got %0d expected 230", out_X);
    if (out_Y !== 8'd80) $fatal(1,"Vector 4: out_Y got %0d expected 80", out_Y);
    if (out_Z !== 8'd106) $fatal(1,"Vector 4: out_Z got %0d expected 106", out_Z);
    if (out_Q !== 8'd88) $fatal(1,"Vector 4: out_Q got %0d expected 88", out_Q);
    // Independent reference vector 5
    @(negedge clk);
    in_A = 8'd189;
    in_B = 8'd208;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 5: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd141) $fatal(1,"Vector 5 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd189) $fatal(1,"Vector 5 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 5: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 5: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd74) $fatal(1,"Vector 5 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd144) $fatal(1,"Vector 5 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 5: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd141) $fatal(1,"Vector 5: out_X got %0d expected 141", out_X);
    if (out_Y !== 8'd74) $fatal(1,"Vector 5: out_Y got %0d expected 74", out_Y);
    if (out_Z !== 8'd189) $fatal(1,"Vector 5: out_Z got %0d expected 189", out_Z);
    if (out_Q !== 8'd144) $fatal(1,"Vector 5: out_Q got %0d expected 144", out_Q);
    // Independent reference vector 6
    @(negedge clk);
    in_A = 8'd204;
    in_B = 8'd8;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 6: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd212) $fatal(1,"Vector 6 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd204) $fatal(1,"Vector 6 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 6: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 6: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd160) $fatal(1,"Vector 6 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd96) $fatal(1,"Vector 6 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 6: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd212) $fatal(1,"Vector 6: out_X got %0d expected 212", out_X);
    if (out_Y !== 8'd160) $fatal(1,"Vector 6: out_Y got %0d expected 160", out_Y);
    if (out_Z !== 8'd204) $fatal(1,"Vector 6: out_Z got %0d expected 204", out_Z);
    if (out_Q !== 8'd96) $fatal(1,"Vector 6: out_Q got %0d expected 96", out_Q);
    // Independent reference vector 7
    @(negedge clk);
    in_A = 8'd88;
    in_B = 8'd131;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 7: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd219) $fatal(1,"Vector 7 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd88) $fatal(1,"Vector 7 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 7: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 7: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd51) $fatal(1,"Vector 7 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd8) $fatal(1,"Vector 7 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 7: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd219) $fatal(1,"Vector 7: out_X got %0d expected 219", out_X);
    if (out_Y !== 8'd51) $fatal(1,"Vector 7: out_Y got %0d expected 51", out_Y);
    if (out_Z !== 8'd88) $fatal(1,"Vector 7: out_Z got %0d expected 88", out_Z);
    if (out_Q !== 8'd8) $fatal(1,"Vector 7: out_Q got %0d expected 8", out_Q);
    // Independent reference vector 8
    @(negedge clk);
    in_A = 8'd162;
    in_B = 8'd41;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 8: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd203) $fatal(1,"Vector 8 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd162) $fatal(1,"Vector 8 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 8: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 8: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd109) $fatal(1,"Vector 8 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd242) $fatal(1,"Vector 8 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 8: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd203) $fatal(1,"Vector 8: out_X got %0d expected 203", out_X);
    if (out_Y !== 8'd109) $fatal(1,"Vector 8: out_Y got %0d expected 109", out_Y);
    if (out_Z !== 8'd162) $fatal(1,"Vector 8: out_Z got %0d expected 162", out_Z);
    if (out_Q !== 8'd242) $fatal(1,"Vector 8: out_Q got %0d expected 242", out_Q);
    // Independent reference vector 9
    @(negedge clk);
    in_A = 8'd222;
    in_B = 8'd2;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 9: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd224) $fatal(1,"Vector 9 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd222) $fatal(1,"Vector 9 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 9: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 9: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd190) $fatal(1,"Vector 9 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd188) $fatal(1,"Vector 9 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 9: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd224) $fatal(1,"Vector 9: out_X got %0d expected 224", out_X);
    if (out_Y !== 8'd190) $fatal(1,"Vector 9: out_Y got %0d expected 190", out_Y);
    if (out_Z !== 8'd222) $fatal(1,"Vector 9: out_Z got %0d expected 222", out_Z);
    if (out_Q !== 8'd188) $fatal(1,"Vector 9: out_Q got %0d expected 188", out_Q);
    // Independent reference vector 10
    @(negedge clk);
    in_A = 8'd245;
    in_B = 8'd88;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 10: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd77) $fatal(1,"Vector 10 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd245) $fatal(1,"Vector 10 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 10: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 10: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd66) $fatal(1,"Vector 10 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd56) $fatal(1,"Vector 10 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 10: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd77) $fatal(1,"Vector 10: out_X got %0d expected 77", out_X);
    if (out_Y !== 8'd66) $fatal(1,"Vector 10: out_Y got %0d expected 66", out_Y);
    if (out_Z !== 8'd245) $fatal(1,"Vector 10: out_Z got %0d expected 245", out_Z);
    if (out_Q !== 8'd56) $fatal(1,"Vector 10: out_Q got %0d expected 56", out_Q);
    // Independent reference vector 11
    @(negedge clk);
    in_A = 8'd24;
    in_B = 8'd156;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 11: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd180) $fatal(1,"Vector 11 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd24) $fatal(1,"Vector 11 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 11: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 11: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd204) $fatal(1,"Vector 11 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd160) $fatal(1,"Vector 11 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 11: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd180) $fatal(1,"Vector 11: out_X got %0d expected 180", out_X);
    if (out_Y !== 8'd204) $fatal(1,"Vector 11: out_Y got %0d expected 204", out_Y);
    if (out_Z !== 8'd24) $fatal(1,"Vector 11: out_Z got %0d expected 24", out_Z);
    if (out_Q !== 8'd160) $fatal(1,"Vector 11: out_Q got %0d expected 160", out_Q);
    // Independent reference vector 12
    @(negedge clk);
    in_A = 8'd159;
    in_B = 8'd225;
    start=1;
    @(negedge clk); start=0;
    repeat (2) @(negedge clk);
    if (!busy || done || step_debug !== 2'd0) $fatal(1,"Vector 12: controller advanced without enable");
    // Actual scheduled cycle 1; step counter 0
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd128) $fatal(1,"Vector 12 step 0: add_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd1) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd1) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 2; step counter 1
    step_enable=1;
    #1;
    if (fu_sub_0_out !== 8'd159) $fatal(1,"Vector 12 step 1: sub_0 mismatch");
    @(negedge clk); step_enable=0;
    if (!busy || done || step_debug !== 2'd2) $fatal(1,"Vector 12: incorrect step advance");
    repeat (2) @(negedge clk);
    if (!busy || step_debug !== 2'd2) $fatal(1,"Vector 12: advanced while paused");
    // Actual scheduled cycle 3; step counter 2
    step_enable=1;
    #1;
    if (fu_add_0_out !== 8'd31) $fatal(1,"Vector 12 step 2: add_0 mismatch");
    if (fu_mul_0_out !== 8'd191) $fatal(1,"Vector 12 step 2: mul_0 mismatch");
    @(negedge clk); step_enable=0;
    if (busy || !done) $fatal(1,"Vector 12: done/busy incorrect at completion");
    repeat (2) @(negedge clk);
    if (out_X !== 8'd128) $fatal(1,"Vector 12: out_X got %0d expected 128", out_X);
    if (out_Y !== 8'd31) $fatal(1,"Vector 12: out_Y got %0d expected 31", out_Y);
    if (out_Z !== 8'd159) $fatal(1,"Vector 12: out_Z got %0d expected 159", out_Z);
    if (out_Q !== 8'd191) $fatal(1,"Vector 12: out_Q got %0d expected 191", out_Q);
    $display("PASS: all generated test vectors passed");
$finish;
  end
endmodule
