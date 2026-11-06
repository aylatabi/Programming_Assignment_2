# Parser test files

- `valid/`: should parse with no errors and no warnings.
- `invalid/`: should fail with the error(s) described; the tool exits non-zero.
- `warnings/`: should parse successfully but print the warning described.

Every file except `empty_file.txt` starts with two comment lines:

- `# EXPECT:` the expected result. Line numbers count from the top of the file, including these comment lines. Columns are 1-based.
- `# TESTS:` what the file is checking.

`invalid/empty_file.txt` is a zero-byte file (it can't hold a comment). Expected: `error: no equations found`.

Conventions these files assume: `#` starts a comment, names are case-sensitive, constants are non-negative integers, and names ending in `_<digits>` are reserved for SSA versions (`X_1`).
