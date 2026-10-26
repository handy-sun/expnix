# Bulk `unsafe` Wrapping for `env::set_var`/`remove_var`

Rust 1.83+ makes `std::env::set_var` and `std::env::remove_var` `unsafe fn`.
Legacy codebases have hundreds of bare calls. This is a migration recipe.

## Search Patterns

Two dominant patterns in test code:

### Pattern 1: Standalone statements
```rust
// Before
std::env::set_var("HOME", home);
std::env::remove_var("CC_SWITCH_CONFIG_DIR");

// After
unsafe { std::env::set_var("HOME", home) };
unsafe { std::env::remove_var("CC_SWITCH_CONFIG_DIR") };
```

### Pattern 2: Match arms (save/restore guard)
```rust
// Before
match &self.original {
    Some(value) => std::env::set_var("HOME", value),
    None => std::env::remove_var("HOME"),
}

// After
match &self.original {
    Some(value) => unsafe { std::env::set_var("HOME", value) },
    None => unsafe { std::env::remove_var("HOME") },
}
```

### Pattern 3: Multi-line blocks
```rust
// Before
std::env::set_var("HOME", home);
std::env::set_var("USERPROFILE", home);
std::env::set_var("CC_SWITCH_CONFIG_DIR", home.join(".cc-switch"));

// After
unsafe {
    std::env::set_var("HOME", home);
    std::env::set_var("USERPROFILE", home);
    std::env::set_var("CC_SWITCH_CONFIG_DIR", home.join(".cc-switch"));
}
```

## Bulk Script Approach

Use `search_files` to find all occurrences, then group by file and apply
`patch` calls in batches. Prioritize by pattern type:

1. Match arms (most common in guard Drop impls) — regex `=>\s*std::env::(set_var|remove_var)`
2. Standalone statements — regex `^\s+std::env::(set_var|remove_var)\(`
3. Already-unsafe calls — skip (check for `unsafe { std::env::set_var`)

## Pitfalls

- `#[cfg(test)]` blocks need `unsafe` too — the compiler doesn't care about cfg
- `use std::env;` aliased calls: `env::set_var(...)` also need `unsafe`
- Some calls may already be inside an `unsafe` block — don't double-wrap
- Match arm RHS must be wrapped, not the whole match: `=> unsafe { ... }` not `unsafe { match ... }`
