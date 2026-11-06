"""Equation-file parser (Part 1).

Built as three passes:
  1. Clean-up            -- raw text -> meaningful lines
  2. Tokenize + shape     -- each line -> one equation record
  3. Whole-file checks    -- limits, input detection, warnings

Main entry point: parse_source(text) -> ParseResult

Try it on any equation files:
    python -m hls.parser FILE [FILE ...]           # all passes: equations, inputs, errors, warnings
    python -m hls.parser --pass1 FILE [FILE ...]   # pass 1 only: cleaned lines
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from enum import Enum

COMMENT_MARKER = "#"

MAX_EQUATIONS = 20  # limit from the assignment spec

# Hardware-dependent defaults used by pass 3's warnings. These are placeholders:
# set them to the real datapath width and the number of input variables the
# board wrapper can take from switches, once those are decided.
DEFAULT_BIT_WIDTH = 8
DEFAULT_MAX_SWITCH_INPUTS = 4


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class CleanLine:
    """One non-empty line after clean-up.

    number  -- 1-based line number in the original file
    text    -- the line with comment, surrounding whitespace and one trailing ';' removed
    offset  -- how many characters were cut from the front, so that
               original column = (index in text) + 1 + offset
    raw     -- the original line (without its line ending), for error messages
    """

    number: int
    text: str
    offset: int
    raw: str


class Op(Enum):
    ADD = "+"
    SUB = "-"
    MUL = "*"


@dataclass(frozen=True)
class Var:
    name: str

    def __str__(self) -> str:
        return self.name


@dataclass(frozen=True)
class Const:
    value: int

    def __str__(self) -> str:
        return str(self.value)


Operand = Var | Const


@dataclass(frozen=True)
class Equation:
    """One parsed equation: dest = left op right."""

    dest: str
    op: Op
    left: Operand
    right: Operand
    line: int  # line number in the original file

    def __str__(self) -> str:
        return f"{self.dest} = {self.left} {self.op.value} {self.right}"


@dataclass(frozen=True)
class Diagnostic:
    """An error or warning. line/col are 1-based; either may be None."""

    severity: str  # "error" or "warning"
    message: str
    line: int | None = None
    col: int | None = None
    source_line: str | None = None  # original text of the line, for the caret display


@dataclass
class ParseResult:
    equations: list[Equation] = field(default_factory=list)
    diagnostics: list[Diagnostic] = field(default_factory=list)
    # Variables read before they are ever assigned, in order of first use.
    # Filled by pass 3, and only when there are no errors.
    inputs: list[str] = field(default_factory=list)

    @property
    def errors(self) -> list[Diagnostic]:
        return [d for d in self.diagnostics if d.severity == "error"]

    @property
    def ok(self) -> bool:
        return not self.errors


# ---------------------------------------------------------------------------
# Pass 1: clean-up
# ---------------------------------------------------------------------------

def read_source(path: str) -> str:
    """Read an equation file as text.

    'utf-8-sig' removes a byte-order mark if there is one. newline='' keeps
    '\\r' characters so clean_lines() handles every line-ending style itself.
    Raises OSError or UnicodeDecodeError; the caller reports them.
    """
    with open(path, encoding="utf-8-sig", newline="") as f:
        return f.read()


def clean_lines(source: str) -> list[CleanLine]:
    """Pass 1: turn raw file text into the lines that hold equations.

    Removes comments, surrounding whitespace and one trailing ';', and drops
    lines left empty. Line numbers always refer to the original file.
    """
    # Normalise Windows (\r\n) and old Mac (\r) endings to \n. str.splitlines()
    # is avoided on purpose: it also splits on form feeds and other rare
    # characters, which would shift line numbers.
    source = source.replace("\r\n", "\n").replace("\r", "\n")

    result: list[CleanLine] = []
    for number, raw in enumerate(source.split("\n"), start=1):
        text = raw

        comment_at = text.find(COMMENT_MARKER)
        if comment_at != -1:
            text = text[:comment_at]

        text = text.rstrip()
        if text.endswith(";"):
            text = text[:-1].rstrip()

        stripped = text.lstrip()
        offset = len(text) - len(stripped)
        text = stripped

        if text:
            result.append(CleanLine(number, text, offset, raw))

    return result


# ---------------------------------------------------------------------------
# Pass 2: tokenizer + line-shape check
# ---------------------------------------------------------------------------

class Tok(Enum):
    NAME = "name"
    NUMBER = "number"
    EQUALS = "'='"
    OP = "operator"


@dataclass(frozen=True)
class Token:
    kind: Tok
    text: str
    col: int  # 1-based column in the original line


class LineError(Exception):
    """Raised inside pass 2 for the first problem found on a line."""

    def __init__(self, message: str, col: int | None = None):
        super().__init__(message)
        self.message = message
        self.col = col


# Characters that look like operators but aren't supported, so the message
# can say "unsupported operator" instead of just "unexpected character".
UNSUPPORTED_OPERATOR_CHARS = set("/%^&|<>!~")

# Verilog-2005 reserved words. A variable with one of these names would
# break the generated RTL. Verilog is case-sensitive, so only exact matches.
VERILOG_KEYWORDS = frozenset("""
    always and assign automatic begin buf bufif0 bufif1 case casex casez cell
    cmos config deassign default defparam design disable edge else end endcase
    endconfig endfunction endgenerate endmodule endprimitive endspecify
    endtable endtask event for force forever fork function generate genvar
    highz0 highz1 if ifnone incdir include initial inout input instance integer
    join large liblist library localparam macromodule medium module nand
    negedge nmos nor noshowcancelled not notif0 notif1 or output parameter
    pmos posedge primitive pull0 pull1 pulldown pullup pulsestyle_ondetect
    pulsestyle_onevent rcmos real realtime reg release repeat rnmos rpmos
    rtran rtranif0 rtranif1 scalared showcancelled signed small specify
    specparam strong0 strong1 supply0 supply1 table task time tran tranif0
    tranif1 tri tri0 tri1 triand trior trireg unsigned use uwire vectored wait
    wand weak0 weak1 while wire wor xnor xor
""".split())

# Port and signal names used by the generated hardware. Update this set to
# match the real top-level / FSM port names once they are decided.
RESERVED_PORT_NAMES = frozenset({"clk", "rst", "reset", "step", "sel", "start", "done"})

# SSA renames X to X_1, X_2, ... so user names may not already look like that.
SSA_SUFFIX = re.compile(r"_\d+$")


def tokenize(line: CleanLine) -> list[Token]:
    """Split a cleaned line into tokens. Raises LineError on a bad character or name."""
    text = line.text
    tokens: list[Token] = []
    i = 0
    while i < len(text):
        ch = text[i]
        col = i + 1 + line.offset

        if ch.isspace():
            i += 1
            continue

        if ch.isalnum() or ch == "_":
            # Read the whole word, then decide whether it is a name or a number.
            j = i
            while j < len(text) and (text[j].isalnum() or text[j] == "_"):
                j += 1
            word = text[i:j]
            if not word.isascii():
                raise LineError(f"invalid name '{word}' (only ASCII letters, digits and '_' allowed)", col)
            if word.isdigit():
                tokens.append(Token(Tok.NUMBER, word, col))
            elif word[0].isdigit():
                raise LineError(f"invalid name '{word}' (names must start with a letter or underscore)", col)
            else:
                tokens.append(Token(Tok.NAME, word, col))
            i = j
            continue

        if ch == "=":
            tokens.append(Token(Tok.EQUALS, ch, col))
        elif ch in "+-*":
            tokens.append(Token(Tok.OP, ch, col))
        elif ch in UNSUPPORTED_OPERATOR_CHARS:
            raise LineError(f"unsupported operator '{ch}' (only + - * allowed)", col)
        else:
            raise LineError(f"unexpected character '{ch}'", col)
        i += 1

    return tokens


def _describe(tok: Token) -> str:
    return f"'{tok.text}'"


def _check_name(tok: Token) -> None:
    """Reject names that would clash with the generated Verilog or SSA names."""
    name = tok.text
    if name in VERILOG_KEYWORDS:
        raise LineError(f"'{name}' is a Verilog keyword and cannot be a variable name", tok.col)
    if name in RESERVED_PORT_NAMES:
        raise LineError(f"'{name}' is reserved for the hardware ports", tok.col)
    if SSA_SUFFIX.search(name):
        raise LineError(f"name '{name}' ends in _<digits>, which is reserved for SSA versions", tok.col)


def _operand(tokens: list[Token], i: int, after: Token) -> Operand:
    """Read the operand at tokens[i]; `after` is the token before it (for messages)."""
    if i >= len(tokens):
        raise LineError(f"expected an operand after {_describe(after)}")

    tok = tokens[i]
    if tok.kind is Tok.NAME:
        _check_name(tok)
        return Var(tok.text)
    if tok.kind is Tok.NUMBER:
        return Const(int(tok.text))

    if tok.kind is Tok.OP and tok.text == "-" and i + 1 < len(tokens):
        nxt = tokens[i + 1].kind
        if nxt is Tok.NUMBER:
            raise LineError("expected an operand, found '-' (negative constants not supported)", tok.col)
        if nxt is Tok.NAME:
            raise LineError("expected an operand, found '-' (unary minus not supported)", tok.col)
    raise LineError(f"expected an operand, found {_describe(tok)}", tok.col)


def parse_line(line: CleanLine) -> Equation:
    """Check that a line has the shape  NAME = OPERAND OP OPERAND  and build its record."""
    tokens = tokenize(line)

    equals = [t for t in tokens if t.kind is Tok.EQUALS]
    if not equals:
        raise LineError("missing '='")
    if len(equals) > 1:
        raise LineError("more than one '='", equals[1].col)

    # Destination
    first = tokens[0]
    if first.kind is Tok.EQUALS:
        raise LineError("expected a variable name before '='", first.col)
    if first.kind is Tok.NUMBER:
        raise LineError(f"destination must be a variable, found constant '{first.text}'", first.col)
    if first.kind is not Tok.NAME:
        raise LineError(f"expected a variable name, found {_describe(first)}", first.col)
    _check_name(first)

    # '='
    if tokens[1].kind is not Tok.EQUALS:
        raise LineError(f"expected '=' after '{first.text}', found {_describe(tokens[1])}", tokens[1].col)
    if len(tokens) == 2:
        raise LineError("nothing after '='")

    # left OP right
    left = _operand(tokens, 2, tokens[1])
    if len(tokens) == 3:
        raise LineError(f"expected an operator after {_describe(tokens[2])}")
    op_tok = tokens[3]
    if op_tok.kind is not Tok.OP:
        raise LineError(f"expected an operator, found {_describe(op_tok)}", op_tok.col)
    right = _operand(tokens, 4, op_tok)

    if len(tokens) > 5:
        extra = tokens[5]
        if extra.kind is Tok.OP:
            msg = f"unexpected {_describe(extra)} after second operand (one operator per line)"
        else:
            msg = f"unexpected {_describe(extra)} after second operand"
        raise LineError(msg, extra.col)

    return Equation(first.text, Op(op_tok.text), left, right, line.number)


def parse_lines(lines: list[CleanLine]) -> ParseResult:
    """Pass 2: parse every cleaned line, collecting one error per bad line."""
    result = ParseResult()
    for line in lines:
        try:
            result.equations.append(parse_line(line))
        except LineError as e:
            result.diagnostics.append(Diagnostic("error", e.message, line.number, e.col, line.raw))
    return result


# ---------------------------------------------------------------------------
# Pass 3: whole-file checks
# ---------------------------------------------------------------------------

def find_inputs(equations: list[Equation]) -> list[str]:
    """Variables read before they are first assigned, in order of first use.

    In  X = X + A  the right side is read before X is written, so X counts
    as an input if it was not assigned on an earlier line.
    """
    assigned: set[str] = set()
    inputs: list[str] = []
    for eq in equations:
        for operand in (eq.left, eq.right):
            if isinstance(operand, Var) and operand.name not in assigned and operand.name not in inputs:
                inputs.append(operand.name)
        assigned.add(eq.dest)
    return inputs


def find_dead_assignments(equations: list[Equation]) -> list[Diagnostic]:
    """Warn when a value is overwritten before anything reads it."""
    warnings: list[Diagnostic] = []
    last_write: dict[str, int] = {}  # variable -> line of its latest assignment
    read_since_write: dict[str, bool] = {}

    for eq in equations:
        # The right side is read first, so  X = X + A  does read the old X.
        for operand in (eq.left, eq.right):
            if isinstance(operand, Var):
                read_since_write[operand.name] = True

        if eq.dest in last_write and not read_since_write[eq.dest]:
            warnings.append(Diagnostic(
                "warning",
                f"value of '{eq.dest}' is overwritten on line {eq.line} before it is read",
                last_write[eq.dest],
            ))
        last_write[eq.dest] = eq.line
        read_since_write[eq.dest] = False

    return warnings


def check_program(
    lines: list[CleanLine],
    result: ParseResult,
    bit_width: int = DEFAULT_BIT_WIDTH,
    max_switch_inputs: int = DEFAULT_MAX_SWITCH_INPUTS,
) -> None:
    """Pass 3: checks that need the whole file. Adds to `result` in place."""
    if not lines:
        result.diagnostics.append(Diagnostic("error", "no equations found"))
        return

    if len(lines) > MAX_EQUATIONS:
        extra = lines[MAX_EQUATIONS]
        result.diagnostics.append(Diagnostic(
            "error",
            f"{len(lines)} equations found, maximum is {MAX_EQUATIONS} "
            f"(first extra one is on line {extra.number})",
        ))

    # The remaining checks need a complete, correct program. Inputs or
    # warnings worked out from a file with bad lines would be misleading.
    if not result.ok:
        return

    result.inputs = find_inputs(result.equations)
    result.diagnostics.extend(find_dead_assignments(result.equations))

    max_value = (1 << bit_width) - 1
    for eq in result.equations:
        for operand in (eq.left, eq.right):
            if isinstance(operand, Const) and operand.value > max_value:
                result.diagnostics.append(Diagnostic(
                    "warning",
                    f"constant {operand.value} does not fit in {bit_width} bits (max {max_value})",
                    eq.line,
                ))

    if len(result.inputs) > max_switch_inputs:
        hardcoded = result.inputs[max_switch_inputs:]
        result.diagnostics.append(Diagnostic(
            "warning",
            f"{len(result.inputs)} input variables, but the board takes {max_switch_inputs} "
            f"from switches; these will be hardcoded: {', '.join(hardcoded)}",
        ))


# ---------------------------------------------------------------------------
# Running the passes
# ---------------------------------------------------------------------------

def parse_source(
    source: str,
    bit_width: int = DEFAULT_BIT_WIDTH,
    max_switch_inputs: int = DEFAULT_MAX_SWITCH_INPUTS,
) -> ParseResult:
    """Run all three passes on file text."""
    lines = clean_lines(source)
    result = parse_lines(lines)
    check_program(lines, result, bit_width, max_switch_inputs)
    return result


def format_diagnostic(path: str, d: Diagnostic) -> str:
    """Render as  path:line:col: severity: message  plus the line and a caret."""
    where = path
    if d.line is not None:
        where += f":{d.line}"
        if d.col is not None:
            where += f":{d.col}"
    out = f"{where}: {d.severity}: {d.message}"
    if d.source_line is not None:
        out += f"\n    {d.source_line}"
        if d.col is not None:
            # Keep tabs as tabs so the caret lines up with the original text.
            pad = "".join("\t" if c == "\t" else " " for c in d.source_line[: d.col - 1])
            out += f"\n    {pad}^"
    return out


# ---------------------------------------------------------------------------
# Debug entry point
# ---------------------------------------------------------------------------

def _load(path: str) -> str | None:
    try:
        return read_source(path)
    except OSError as e:
        print(f"{path}: error: cannot read file: {e.strerror}")
    except UnicodeDecodeError:
        print(f"{path}: error: file is not UTF-8 text")
    return None


def _show_pass1(path: str) -> int:
    print(f"== {path}")
    source = _load(path)
    if source is None:
        return 1
    lines = clean_lines(source)
    if not lines:
        print("   (no lines kept)")
    for line in lines:
        print(f"   line {line.number:>2}  offset {line.offset}  {line.text!r}")
    return 0


def _show_parse(path: str) -> int:
    print(f"== {path}")
    source = _load(path)
    if source is None:
        return 1
    result = parse_source(source)
    for eq in result.equations:
        print(f"   line {eq.line:>2}: {eq}")
    if result.ok:
        print(f"   inputs: {' '.join(result.inputs) or '(none)'}")
    for d in result.diagnostics:
        print(format_diagnostic(path, d))
    return 0 if result.ok else 1


if __name__ == "__main__":
    args = sys.argv[1:]
    show = _show_parse
    if args and args[0] == "--pass1":
        show = _show_pass1
        args = args[1:]
    if not args:
        print("usage: python -m hls.parser [--pass1] FILE [FILE ...]")
        sys.exit(2)
    status = 0
    for p in args:
        status |= show(p)
    sys.exit(status)
