# Security Audit — stride-owasp-full-audit

**Date:** 2026-05-06 15:14
**Scope:** /root/calctron/src/*.zig, build.zig (entire codebase — 7 files, 883 lines)
**Focus:** Comprehensive — memory safety, concurrency, input validation, build security
**Iterations:** 30 completed (bounded)
**Duration:** Complete

## Summary

- **Total Findings:** 14
  - Critical: 1 | High: 3 | Medium: 5 | Low: 4 | Info: 1
- **Fixed:** 4 (1 Critical, 3 High) — all Critical/High auto-remediated
- **Remaining:** 10 (5 Medium, 4 Low, 1 Info)
- **STRIDE Coverage:** 5/6 categories tested (E not applicable — no privilege levels)
- **OWASP Coverage:** 6/8 applicable categories tested (A07, A10 not applicable)
- **Confirmed:** 13 | Likely: 1 | Possible: 0
- **Clean Checks:** 16
- **Security Score:** 69/100 (pre-fix) → improved post-fix

## Fixes Applied

| # | Severity | Finding | Status | Files |
|---|----------|---------|--------|-------|
| 1 | Critical | Factorial DoS — no upper bound | ✅ Fixed | calculator.zig, parallel.zig |
| 2 | High | getDisplayText buffer corruption | ✅ Fixed | calculator.zig |
| 3 | High | Negative button dimensions on resize | ✅ Fixed | ui.zig |
| 4 | High | Silent factorial overflow | ✅ Fixed | parallel.zig, calculator.zig |

## Top 3 Findings (All Critical/High Fixed)

1. ~~[Factorial Denial of Service](./findings.md#critical-finding-1)~~ **✅ Fixed** — Added upper bound (170) and error union return
2. ~~[getDisplayText Buffer Corruption](./findings.md#high-finding-2)~~ **✅ Fixed** — Separate display_op buffer prevents mutation
3. ~~[Negative Button Dimensions](./findings.md#high-finding-3)~~ **✅ Fixed** — Clamped btn_w with @max(raw, 20.0)

## Files in This Report

- [Threat Model](./threat-model.md) — STRIDE analysis, assets, trust boundaries
- [Attack Surface Map](./attack-surface-map.md) — entry points, data flows, abuse paths
- [Findings](./findings.md) — all findings ranked by severity
- [OWASP Coverage](./owasp-coverage.md) — per-category test results
- [Dependency Audit](./dependency-audit.md) — known CVEs in dependencies
- [Recommendations](./recommendations.md) — prioritized mitigations
- [Iteration Log](./security-audit-results.tsv) — raw data from every iteration
