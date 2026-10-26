---
name: cpp-code-review
description: Review C/C++ codebases for bugs, vulnerabilities, and quality issues. Covers Qt5 patterns, memory safety, buffer overflows, CMake pitfalls, and cross-platform gotchas.
tags: [cpp, qt5, code-review, security, cmake, memory-safety]
---

# C/C++ Code Review

Systematic review of C/C++ codebases for correctness, security, and quality. Specialized for Qt5 desktop applications but applicable to general C/C++ code.

## When to Use

- Reviewing a C/C++ codebase for the first time
- Before merging C/C++ changes
- Auditing Qt5 plugin architectures
- Security review of native code

## Review Workflow

1. **Save findings first**: Write all issues to a structured file (e.g., `problem.md`) before fixing anything
2. **Fix Critical tier first**: Security vulnerabilities, crashes, data corruption
3. **Then Important**: Resource leaks, logic errors, UI bugs
4. **Then Suggestions**: Style, deprecated APIs, build improvements
5. Each issue entry: severity, `file:line`, description, fix suggestion

## Concurrency & Mutex Patterns

- **Mutex deadlock on early return**: Manual `mutex.lock()` + early `return` without `mutex.unlock()` = permanent deadlock. Always use `QMutexLocker` for RAII-safe locking.
- **`processEvents()` re-entrancy**: Calling `QCoreApplication::processEvents()` inside a slot can trigger re-entrant calls. Avoid in synchronous contexts.
- **Timer + null pointer**: If a function deletes an object and sets the pointer to `nullptr` but doesn't stop associated timers, the timer callback dereferences null. Always stop timers before deleting the target.

## Buffer & Memory Safety

- **`qstrcpy` to fixed-size `char[]`**: `qstrcpy(dst, "0000")` writes 5 bytes (including `\0`) to a 4-byte field. Use `memcpy(dst, "0000", 4)` for fixed-size struct fields.
- **`memcpy` without size validation**: Always check `buffer.size() >= sizeof(Struct)` before `memcpy(&struct, buffer.constData(), sizeof(Struct))`.
- **Uninitialized output parameters**: If a function conditionally sets `*outParam`, the caller must initialize to 0 before calling. Check all output-parameter paths.
- **`malloc` + early return leak**: Track every `malloc`/`free` pairing. Ensure `free()` on all error paths.
- **Signed shift overflow**: `(ptr[0] << 24)` on a signed int produces negative values when the high bit is set. Use `quint32` or explicit cast.

## Qt Object Lifecycle

- **Static `QObject*` parented to instance**: If a static pointer is parented to a specific instance (`new QThing(this)`), the parent's destruction makes the static pointer dangling. Fix: no parent, or `QPointer<T>` to track validity.
- **Raw pointer containers without ownership**: `QList<T*>` and `QHash<QString, T*>` that don't own their objects leave dangling pointers after Qt's parent-child cleanup. Clear containers in destructors.
- **`QTranslator` load failure**: Failed `load()` leaves the object allocated as a child of `QApplication`. Not a leak (cleaned up at exit), but wasteful.

## String & Encoding

- **ID3v2 syncsafe integers**: All 4 bytes must have bit 7 clear. `size >> 21` needs `& 0x7F` mask. Without it, other players can't read the tag.
- **Hex formatting without zero-padding**: `QString("%1").arg(value, 0, 16)` doesn't pad. Use `arg(value, 2, 16, QChar('0'))` for fixed-width hex.
- **GLSL/C string escaping**: Converting text to C string literals requires escaping `\` → `\\` and `"` → `\"` BEFORE other substitutions.

## Network & I/O

- **Infinite redirect recursion**: Network redirect handlers must have a counter/limit (e.g., max 10). Without it, malicious servers cause stack overflow.
- **`QNetworkReply` leak on error paths**: Ensure `deleteLater()` is called on all error paths.
- **Overwriting active request**: Check if `m_netReply` is already active before starting a new request. `abort()` + `deleteLater()` the old one.
- **Redirect URL scheme validation**: Validate that redirect targets use safe schemes (http/https). `file:///` or `javascript:` redirects can be exploited.
- **Blocking UI thread**: `QEventLoop` nested in the main thread makes the application unresponsive during network requests. Use async signals/slots or worker threads.

## CMake Pitfalls

- **Empty `CMAKE_BUILD_TYPE`**: `if(${CMAKE_BUILD_TYPE} MATCHES "Debug")` evaluates to true when empty. Always quote: `if("${CMAKE_BUILD_TYPE}" MATCHES "Debug")`. Affects multi-config generators (VS, Xcode).
- **Unix-only commands**: `test -d` and `cp -r` don't work on Windows. Use `cmake -E copy_directory` or guard with `if(UNIX)`.
- **`file(GLOB)` for sources**: CMake can't detect added/removed files. Prefer explicit source lists.
- **PCH path context**: Relative paths in precompiled header rules are resolved relative to the subdirectory context, not the project root.

## Common Pitfalls by Severity

### Critical (blocks merge)
- Mutex deadlock on error paths
- Buffer overflow in struct serialization
- Uninitialized variables used for allocation sizes
- Null pointer dereference from timer callbacks
- Static pointer use-after-free

### Important (must fix)
- Resource leaks on error paths
- Infinite recursion / unbounded loops
- Missing input validation before `memcpy`
- Logic errors (`||` vs `&&`)
- Blocking UI thread with synchronous I/O

### Suggestion (improve when touching the file)
- Deprecated Qt APIs (`QDesktopWidget`, `setMargin`)
- `file(GLOB)` for source files
- Missing `inline`/`static` on header-defined functions
- Build output mixed into source tree
