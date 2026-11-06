"""Single Static Assignment conversion (Part 2).

Every assignment gets a new numbered version of its variable, so each name
is written exactly once:

    X = A + B        X_1 = A + B
    X = X + A   ->   X_2 = X_1 + A
    Y = X * B        Y_1 = X_2 * B

Naming rules:
  - Input variables (read before they are ever assigned) keep their plain
    name, e.g. A. The parser rejects user names ending in _<digits>, so a
    plain name can never collide with a version.
  - Assigned variables are numbered from 1: X_1, X_2, ...
  - An operand always refers to the latest version at that point. In
    X = X + A the right side is resolved before X gets its new version.
  - The final version of each assigned variable is a program output.

Main entry point: to_ssa(parse_result) -> SSAProgram
"""

from __future__ import annotations

from dataclasses import dataclass, field

from .parser import Const, Op, Operand, ParseResult, Var


@dataclass(frozen=True)
class SSAStatement:
    """One SSA assignment: dest = left op right.

    dest     -- versioned name, e.g. X_2
    var      -- the original variable name, e.g. X
    version  -- the version number, e.g. 2
    left/right -- Var (versioned name or input name) or Const
    line     -- line number of the source equation
    """

    dest: str
    var: str
    version: int
    op: Op
    left: Operand
    right: Operand
    line: int

    def __str__(self) -> str:
        return f"{self.dest} = {self.left} {self.op.value} {self.right}"


@dataclass
class SSAProgram:
    statements: list[SSAStatement] = field(default_factory=list)
    # Input variable names (unversioned), in order of first use.
    inputs: list[str] = field(default_factory=list)
    # Original variable -> its final SSA version, in order of first assignment.
    outputs: dict[str, str] = field(default_factory=dict)

    def is_input(self, name: str) -> bool:
        return name in self.inputs


def ssa_name(var: str, version: int) -> str:
    return f"{var}_{version}"


def to_ssa(parsed: ParseResult) -> SSAProgram:
    """Convert a parsed, error-free program to SSA form."""
    if not parsed.ok:
        raise ValueError("cannot convert a program with parse errors to SSA")

    program = SSAProgram(inputs=list(parsed.inputs))
    current: dict[str, str] = {}  # variable -> its latest SSA name
    versions: dict[str, int] = {}  # variable -> its latest version number

    def resolve(operand: Operand) -> Operand:
        if isinstance(operand, Const):
            return operand
        # Not assigned yet means it is an input; it keeps its plain name.
        return Var(current.get(operand.name, operand.name))

    for eq in parsed.equations:
        # Read first, then write, so  X = X + A  uses the old X.
        left = resolve(eq.left)
        right = resolve(eq.right)

        version = versions.get(eq.dest, 0) + 1
        versions[eq.dest] = version
        dest = ssa_name(eq.dest, version)
        current[eq.dest] = dest

        program.statements.append(
            SSAStatement(dest, eq.dest, version, eq.op, left, right, eq.line)
        )

    # dict keeps insertion order, so outputs follow order of first assignment.
    program.outputs = dict(current)
    return program


def format_ssa(program: SSAProgram, source_name: str | None = None) -> str:
    """Render the SSA program as text, the format written by --export-ssa."""
    lines: list[str] = []
    header = "# SSA form"
    if source_name:
        header += f" of {source_name}"
    lines.append(header)
    lines.append(f"# inputs:  {' '.join(program.inputs) or '(none)'}")
    outputs = ", ".join(f"{var} -> {name}" for var, name in program.outputs.items())
    lines.append(f"# outputs: {outputs}")
    lines.append("")

    width = max((len(str(s)) for s in program.statements), default=0)
    for s in program.statements:
        lines.append(f"{str(s):<{width}}   # line {s.line}")

    return "\n".join(lines) + "\n"
