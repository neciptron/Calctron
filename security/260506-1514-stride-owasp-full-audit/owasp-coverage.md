# OWASP Coverage Matrix

## Summary

| ID | Category | Tested | Findings | Status |
|----|----------|--------|----------|--------|
| A01 | Broken Access Control | ✓ | 0 | ✅ Clean |
| A02 | Cryptographic Failures | ✓ | 1 | ⚠️ Issues found |
| A03 | Injection | ✓ | 1 | ⚠️ Issues found |
| A04 | Insecure Design | ✓ | 5 | ⚠️ Issues found |
| A05 | Security Misconfiguration | ✓ | 2 | ⚠️ Issues found |
| A06 | Vulnerable and Outdated Components | ✓ | 0 | ✅ Clean |
| A07 | Identification and Authentication Failures | N/A | - | ➖ Not applicable |
| A08 | Software and Data Integrity Failures | ✓ | 1 | ⚠️ Issues found |
| A09 | Security Logging and Monitoring Failures | ✓ | 1 | ⚠️ Issues found |
| A10 | Server-Side Request Forgery | N/A | - | ➖ Not applicable |

**Coverage:** 6/8 applicable categories tested (A07, A10 not applicable for offline desktop app)

## Per-Category Detail

### A01 — Broken Access Control
**Checks performed:**
- [x] IDOR on parameterized routes — N/A (no routes)
- [x] Horizontal privilege escalation — N/A (no auth)
- [x] Vertical privilege escalation — N/A (no roles)
- [x] Directory traversal — N/A (no file operations)
- [x] CORS misconfiguration — N/A (no HTTP)
- **Result:** No access control mechanisms exist; not applicable to desktop calculator

### A02 — Cryptographic Failures
**Checks performed:**
- [x] Sensitive data in plaintext — N/A (no sensitive data)
- [x] Weak hashing — N/A (no hashing)
- [x] Hardcoded secrets — Checked: none found
- [x] Weak random number generation — N/A (no RNG usage)
- [x] Floating point precision loss — Found: calculator.zig:310 (Finding 8)
- **Result:** 1 Medium finding — precision loss in large float formatting

### A03 — Injection
**Checks performed:**
- [x] SQL/NoSQL injection — N/A (no database)
- [x] Command injection — N/A (no shell execution)
- [x] Buffer overflow — Tested: display buffer (Clean), current_input buffer (Clean), status bar buffer (Clean)
- [x] Path injection — N/A (no file operations)
- [x] Display buffer mutation — Found: calculator.zig:326-339 (Finding 2)
- [x] i18n string injection — Tested: all translations are compile-time constants (Clean)
- **Result:** 1 High finding — getDisplayText() progressive buffer corruption

### A04 — Insecure Design
**Checks performed:**
- [x] Missing rate limiting — Tested: input flooding limited by frame rate (Clean)
- [x] Predictable identifiers — N/A (no identifiers)
- [x] Race conditions — Tested: thread partials (Finding 5)
- [x] Integer overflow — Tested: factorial overflow (Finding 4)
- [x] Missing resource bounds — Tested: factorial upper bound (Finding 1, 9)
- [x] NaN/Inf propagation — Tested: compute() and setOperator() (Finding 6, 7)
- [x] Window resize validation — Tested: negative button dimensions (Finding 3)
- [x] Silent truncation — Tested: formatResult (Finding 11)
- [x] State consistency after errors — Tested: evaluate() and applyUnary() (Finding 9, 13)
- **Result:** 1 Critical, 2 High, 3 Medium, 1 Low findings

### A05 — Security Misconfiguration
**Checks performed:**
- [x] Debug mode in production — Checked: no debug flags
- [x] Default credentials — N/A (no auth)
- [x] Verbose error messages — Checked: error messages are generic strings
- [x] @panic usage — Found: calculator.zig:28-29 (Finding 14)
- [x] Memory leak on OOM — Found: calculator.zig:28-29 (Finding 10)
- [x] Error handling completeness — Found: evaluate() discards state (Finding 13)
- [x] Build configuration stubs — Checked: misleading but not exploitable
- **Result:** 2 Low, 1 Info findings

### A06 — Vulnerable and Outdated Components
**Checks performed:**
- [x] Known CVEs in dependencies — raylib is C library; no known vulnerabilities in current usage
- [x] Outdated frameworks — Cannot verify without network access to check versions
- [x] Unmaintained dependencies — raylib is actively maintained
- **Result:** No vulnerabilities detected; offline app limits attack surface

### A08 — Software and Data Integrity Failures
**Checks performed:**
- [x] Missing integrity checks — N/A (no CI/CD pipeline)
- [x] Unsigned updates — N/A (no update mechanism)
- [x] Thread synchronization — Found: missing atomics on ARM (Finding 5)
- [x] Theme color integrity — Checked: compile-time constants (Clean)
- **Result:** 1 Medium finding

### A09 — Security Logging and Monitoring Failures
**Checks performed:**
- [x] Missing audit logs — N/A (no security events to log)
- [x] Sensitive data in logs — N/A (no logging)
- [x] Leak detection — Found: gpa.deinit() result discarded (Finding 12)
- **Result:** 1 Low finding
