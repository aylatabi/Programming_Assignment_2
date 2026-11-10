"""Generate fpga_top.v: the Nexys4 DDR wrapper around generated_system.

The top-level ports are the same for every design, so rtl/nexys4ddr.xdc never
changes. What changes per design (inputs, outputs, functional units) is handled
by the muxes generated here.

Board controls
  SW[7:0]     value to load into the selected input
  BTNL / BTNR pick the previous / next input variable
  BTNU        load SW[7:0] into the selected input
  BTND        start: latch the loaded inputs into the system
  BTNC        step: advance the system one clock cycle
  CPU_RESETN  reset everything
  SW[15:10]   what the display shows (index into SHOW_LIST, printed in the file)

Display (decimal), normal view
  digits 7-6  the SW[15:10] selection number
  digits 5-4  cycle number (0 = not started)
  digits 3-0  value of the selected unit / output / input
Display, input view (about 3 s after pressing BTNL, BTNR or BTNU)
  digits 7-6  input box number (same order as BTNL/BTNR)
  digits 5-4  blank
  digits 3-0  value stored in that input
LEDs
  LED[7:0]    stored value of the input picked with BTNL/BTNR
  LED[12:8]   index of that input
  LED[13]     busy, LED[14] done, LED[15] SW[15:10] selects nothing
"""
from __future__ import annotations

from .binding import bind
from .ir import Design
from .scheduling import latency
from .verilog import outs_units, step_width

SELECT_BITS = 6  # SW[15:10]


def show_list(d: Design, schedule: dict) -> list[str]:
    """Signals the display can show, in SW[15:10] order: units, outputs, inputs."""
    b = bind(d, schedule)
    items = outs_units(b) + list(d.outputs) + list(d.inputs)
    return items[: 1 << SELECT_BITS]


def fpga_top(d: Design, schedule: dict) -> str:
    b = bind(d, schedule)
    w = d.width
    cycles = latency(schedule)
    sw = step_width(cycles)
    ins = list(d.inputs)
    outs = list(d.outputs)
    units = outs_units(b)
    shown = show_list(d, schedule)
    n_in = len(ins)
    iw = max(1, (max(1, n_in) - 1).bit_length())
    sw_value = f"SW[{w - 1}:0]" if w <= 8 else f"{{{w - 8}'d0, SW[7:0]}}"
    in_sel_wide = "in_sel" if iw >= SELECT_BITS else f"{{{SELECT_BITS - iw}'d0, in_sel}}"

    s: list[str] = [
        "// Generated Nexys4 DDR top level. Constraints: rtl/nexys4ddr.xdc.",
        "// Controls: SW[7:0] value, BTNL/BTNR pick input, BTNU load, BTND start,",
        "// BTNC step one cycle, CPU_RESETN reset, SW[15:10] choose what to display.",
        "// Display: [7:6] selection  [5:4] cycle  [3:0] value (decimal).",
        "// For ~3 s after BTNL/BTNR/BTNU: [7:6] input box  [5:4] blank  [3:0] its stored value.",
        "// SW[15:10] selection list:",
    ]
    for i, name in enumerate(shown):
        s.append(f"//   {i:2d}: {name}")
    s.append("// Inputs (BTNL/BTNR order, index on LED[12:8]):")
    for i, name in enumerate(ins):
        s.append(f"//   {i:2d}: {name}")
    s += [
        "module fpga_top #(",
        "    parameter DEBOUNCE_BITS = 20,",
        "    parameter REFRESH_BITS = 17,",
        "    parameter HOLD_BITS = 28        // input view lasts 2**28 clocks, about 2.7 s",
        ") (",
        "    input  wire        CLK100MHZ,",
        "    input  wire        CPU_RESETN,",
        "    input  wire        BTNC, BTNU, BTNL, BTNR, BTND,",
        "    input  wire [15:0] SW,",
        "    output wire [15:0] LED,",
        "    output wire [6:0]  SEG,",
        "    output wire        DP,",
        "    output wire [7:0]  AN",
        ");",
        "  wire clk = CLK100MHZ;",
        "",
        "  // Reset: CPU_RESETN is active low; synchronise it to the clock.",
        "  reg [1:0] rst_sync = 2'b11;",
        "  always @(posedge clk) rst_sync <= {rst_sync[0], ~CPU_RESETN};",
        "  wire rst = rst_sync[1];",
        "",
        "  wire step_p, load_p, prev_p, next_p, start_p;",
        "  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_step  (.clk(clk), .rst(rst), .btn(BTNC), .pulse(step_p));",
        "  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_load  (.clk(clk), .rst(rst), .btn(BTNU), .pulse(load_p));",
        "  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_prev  (.clk(clk), .rst(rst), .btn(BTNL), .pulse(prev_p));",
        "  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_next  (.clk(clk), .rst(rst), .btn(BTNR), .pulse(next_p));",
        "  pa2_debounce #(.BITS(DEBOUNCE_BITS)) db_start (.clk(clk), .rst(rst), .btn(BTND), .pulse(start_p));",
        "",
        f"  wire [{w - 1}:0] sw_value = {sw_value};",
        "",
        "  // Input values loaded from the switches",
        f"  reg [{iw - 1}:0] in_sel;",
    ]
    for a in ins:
        s.append(f"  reg [{w - 1}:0] val_{a};")
    s += [
        "  always @(posedge clk) begin",
        "    if (rst) begin",
        f"      in_sel <= {iw}'d0;",
    ]
    for a in ins:
        s.append(f"      val_{a} <= {w}'d0;")
    s.append("    end else begin")
    if n_in:
        last = n_in - 1
        s += [
            f"      if (next_p) in_sel <= (in_sel == {iw}'d{last}) ? {iw}'d0 : in_sel + 1'b1;",
            f"      else if (prev_p) in_sel <= (in_sel == {iw}'d0) ? {iw}'d{last} : in_sel - 1'b1;",
            "      if (load_p) begin",
            "        case (in_sel)",
        ]
        for i, a in enumerate(ins):
            s.append(f"          {iw}'d{i}: val_{a} <= sw_value;")
        s += ["          default: ;", "        endcase", "      end"]
    s += ["    end", "  end", ""]

    s.append(f"  reg [{w - 1}:0] in_sel_value;")
    s += ["  always @* begin", "    case (in_sel)"]
    for i, a in enumerate(ins):
        s.append(f"      {iw}'d{i}: in_sel_value = val_{a};")
    s += [f"      default: in_sel_value = {w}'d0;", "    endcase", "  end", ""]

    # The generated system
    s += [
        "  wire busy, done;",
        f"  wire [{sw - 1}:0] step;",
    ]
    for name in outs + units:
        s.append(f"  wire [{w - 1}:0] {name};")
    conns = [
        ".clk(clk)", ".rst(rst)", ".start(start_p)", ".step_enable(step_p)",
        ".busy(busy)", ".done(done)", ".step_debug(step)",
    ]
    conns += [f".{a}(val_{a})" for a in ins]
    conns += [f".{n}({n})" for n in outs + units]
    s.append("  generated_system sys (")
    s.append(",\n".join("    " + c for c in conns))
    s += ["  );", ""]

    # Display selection
    s += [
        f"  wire [{SELECT_BITS - 1}:0] show_sel = SW[15:{16 - SELECT_BITS}];",
        f"  reg [{w - 1}:0] shown;",
        "  reg shown_valid;",
        "  always @* begin",
        "    shown_valid = 1'b1;",
        "    case (show_sel)",
    ]
    for i, name in enumerate(shown):
        sig = f"val_{name}" if name in ins else name
        s.append(f"      {SELECT_BITS}'d{i}: shown = {sig};")
    s += [
        f"      default: begin shown = {w}'d0; shown_valid = 1'b0; end",
        "    endcase",
        "  end",
        "",
        "  // Cycle number on the display: 1-based while running, last cycle when done.",
        "  wire [7:0] cycle_no = busy ? {{(8-" + str(sw) + "){1'b0}}, step} + 8'd1 :",
        f"                        done ? 8'd{cycles} : 8'd0;",
        "",
        "  // Input view: after BTNL/BTNR/BTNU, show the input box and its value for a while.",
        "  reg [HOLD_BITS-1:0] hold;",
        "  always @(posedge clk) begin",
        "    if (rst) hold <= {HOLD_BITS{1'b0}};",
        "    else if (prev_p | next_p | load_p) hold <= {HOLD_BITS{1'b1}};",
        "    else if (hold != {HOLD_BITS{1'b0}}) hold <= hold - 1'b1;",
        "  end",
        "  wire input_view = |hold;",
        f"  wire [{SELECT_BITS - 1}:0] in_sel_wide = {in_sel_wide};",
        f"  wire [{SELECT_BITS - 1}:0] disp_sel = input_view ? in_sel_wide : show_sel;",
        "  wire disp_valid = input_view | shown_valid;",
        "",
        "  wire [31:0] v = input_view ? in_sel_value : shown;",
        "  wire [3:0] v0 = v % 10;",
        "  wire [3:0] v1 = (v / 10) % 10;",
        "  wire [3:0] v2 = (v / 100) % 10;",
        "  wire [3:0] v3 = (v / 1000) % 10;",
        "  wire [3:0] c0 = cycle_no % 10;",
        "  wire [3:0] c1 = (cycle_no / 10) % 10;",
        "  wire [3:0] s0 = disp_sel % 10;",
        "  wire [3:0] s1 = disp_sel / 10;",
        "",
        "  pa2_sevenseg #(.REFRESH_BITS(REFRESH_BITS)) disp (",
        "    .clk(clk), .rst(rst),",
        "    .digits({s1, s0, c1, c0, v3, v2, v1, v0}),",
        "    // Hide the cycle in input view, value digits when nothing is selected,",
        "    // and leading zeros of the value.",
        "    .blank({2'b00, input_view, input_view,",
        "            ~disp_valid | (v < 1000), ~disp_valid | (v < 100),",
        "            ~disp_valid | (v < 10), ~disp_valid}),",
        "    .seg(SEG), .an(AN));",
        "  assign DP = 1'b1;",
        "",
    ]
    led_val = "in_sel_value[7:0]" if w >= 8 else f"{{{8 - w}'d0, in_sel_value}}"
    led_sel = f"in_sel[4:0]" if iw >= 5 else f"{{{5 - iw}'d0, in_sel}}"
    s += [
        f"  assign LED[7:0]  = {led_val};",
        f"  assign LED[12:8] = {led_sel};",
        "  assign LED[13]   = busy;",
        "  assign LED[14]   = done;",
        "  assign LED[15]   = ~shown_valid;",
        "endmodule",
        "",
    ]
    return "\n".join(s)
