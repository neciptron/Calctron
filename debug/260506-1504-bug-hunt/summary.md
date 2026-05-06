# Debug Summary — Calctron

**Date:** 2026-05-06
**Scope:** Entire codebase (6 Zig source files)
**Technique:** Static analysis / direct inspection (Zig binary unavailable on network)
**Iterations:** 11 (7 bugs confirmed, 4 hypotheses disproven)

## Results

| Metric | Value |
|--------|-------|
| Files scanned | 6 |
| Bugs found | 7 |
| Critical | 3 |
| High | 2 |
| Medium | 1 |
| Low | 1 |
| Hypotheses disproven | 4 |

## Critical Bugs (Must Fix Before Build)

1. **parallel.zig:28-32** — Thread args use-after-scope race condition
2. **calculator.zig:260** — `math.log(val)` compile error, use `math.ln(val)`
3. **ui.zig:143** — Button array [25] too small, needs [40] for scientific mode

## High Severity (Feature Broken)

4. **main.zig:34** — R key theme toggle is dead code (consumed by handleInput)
5. **calculator.zig:338** — Operator suffix never displayed (returns wrong value)

## Medium/Low

6. **calculator.zig:66** — Number key enum mapping relies on ASCII coincidence
7. **parallel.zig:9** — Dead variable (Zig compile error)

## Recommendations

- Fix all 3 Critical bugs before attempting to build
- The R key conflict (High) and display bug (High) affect core UX
- Consider switching from array-based button storage to `std.ArrayList` in ui.zig to prevent future sizing issues
- Use named KeyboardKey enum variants instead of `@enumFromInt` for robustness

## Debug Score

```
debug_score = 7 * 15          (bugs found)
            + 11 * 3           (hypotheses tested)
            + (6 / 6) * 40     (files investigated)
            + (2 / 7) * 10     (techniques used: direct inspection, pattern search)
            = 105 + 33 + 40 + 5.7
            = 183.7
```
