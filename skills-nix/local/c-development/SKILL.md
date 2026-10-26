---
name: c-development
description: Guidelines for C/C++ development — code style, comments, compilation, and project conventions.
---

# C/C++ Development

## Code Comments

ALL comments must be in English. No Chinese, no mixed-language comments.

- Use `//` for single-line comments
- Use `/* */` for multi-line or block-commented code
- Keep comments concise and technical — describe *what* and *why*, not *how* (the code shows how)

## Compilation

### Static linking

Static binaries avoid runtime dependency issues. Use musl for clean static linking when available:

```bash
gcc -static -o output source.c
# or with musl
musl-gcc -static -o output source.c
```

### Common flags

```bash
-Wall -Wextra          # warnings
-g                     # debug symbols
-O2                    # optimization
```

## Linux System Programming

### NixOS binary locations

Standard binaries on NixOS live under `/run/wrappers/bin/` (setuid wrapper) rather than `/usr/bin/`. When a program needs to find a system binary, try multiple paths in order:

```c
static const char *bin_paths[] = {
    "/usr/bin/<name>",
    "/bin/<name>",
    "/run/wrappers/bin/<name>",  // NixOS setuid wrapper
    NULL
};
```

## Git Conventions

When committing C changes, use conventional commits:
- `fix(scope): description` for bugfixes
- `feat(scope): description` for new features
- `refactor(scope): description` for restructuring
