---
name: rust-struct-field-propagation
description: Add a new field to a Rust struct and propagate it to all usages across the codebase, including tests. Use when modifying struct definitions, adding enum variants, or encountering "missing field" compilation errors.
triggers:
  - adding a field to a Rust struct
  - "error[E0063]: missing field"
  - adding a variant to an enum used in match arms
  - struct definition changed, tests won't compile
---

# Rust Struct Field Propagation

When adding a new field to a Rust struct (or variant to an enum), all existing initializations must be updated. This is error-prone because usages span multiple contexts.

## Steps

### 1. Add the field to the struct definition

```rust
pub struct VisibleApps {
    pub claude: bool,
    pub codex: bool,
    pub hermes: bool,  // NEW
}
```

### 2. Add to ALL test-local enum/struct copies

Integration tests in `tests/` often define their own local copies of enums and structs. These do NOT inherit from the main crate — they must be updated independently.

```bash
# Find all local definitions
grep -rn "enum AppType" tests/ src/
grep -rn "struct VisibleApps" tests/ src/
grep -rn "struct SkillApps" tests/ src/
```

For each test-local enum copy:
- Add the new variant
- Add corresponding match arms (e.g., `as_str()`, `from_str()`)

### 3. Add field to ALL struct literals

Find every struct literal that needs the new field:

```bash
grep -rn "StructName {" src/ tests/ | grep -v "impl\|fn \|pub "
```

For each, add the field with an appropriate default value.

### 4. Verify with `cargo test --no-run`

**Critical pitfall**: `cargo check` does NOT compile test code. Always use:

```bash
cargo test --no-run 2>&1 | grep "^error"
```

This catches errors in `#[cfg(test)]` modules and `tests/` integration tests that `cargo check` silently skips.

## Pitfalls

### Don't use naive text insertion scripts

Automated scripts that insert text after a keyword (like `openclaw:`) will break match arms, function calls, and other non-struct-literal contexts. Instead:

1. Read each file manually
2. Identify actual struct literal blocks (not match arms, not type annotations)
3. Insert the field with correct indentation

### Match exhaustive enums need new arms

If you add a variant to an enum, ALL match expressions on that enum will fail to compile. Search for:

```bash
grep -rn "match.*app_type\|match.*AppType" src/ tests/
```

### Test-local copies are easy to miss

The most common failure pattern:
1. `cargo check` passes (only checks lib/bin code)
2. `cargo test --no-run` fails (checks test code too)
3. Errors point to `tests/*.rs` files with their own enum/struct definitions

### `serde(default)` doesn't help with struct literals

Even if the new field has `#[serde(default)]`, struct literals in code still require the field explicitly. The serde attribute only helps with deserialization from YAML/JSON/TOML.

## Verification

```bash
# Must show zero errors
cargo test --no-run 2>&1 | grep "^error" | head -5

# Full test run (may take a while)
cargo test 2>&1 | tail -5
```
