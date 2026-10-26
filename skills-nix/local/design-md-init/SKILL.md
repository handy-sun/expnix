---
name: design-md-init
description: >
  Generate DESIGN.md from existing shadcn + Tailwind CSS frontend codebase.
  Read-only audit of visual identity, layout strategy, component paradigms, and styling rules.
triggers:
  - "generate DESIGN.md"
  - "create DESIGN.md"
  - "design spec"
  - "design document"
  - "前端设计规范"
---

# DESIGN.md Generator for shadcn + Tailwind CSS Projects

## Role
高级前端架构师 & DESIGN.md 维护者 — act as an Orchestrator, dispatching concurrent sub-agents and parallel tool calls to audit the codebase in **READ ONLY** mode.

## Execution Strategy

### Concurrency
- Use `delegate_task` to spawn parallel sub-agents for different analysis dimensions (visual, layout, component, styling).
- Use concurrent function calls wherever possible (e.g., reading multiple files simultaneously).

### Scope
- **INCLUDE**: `src/` directory — all business `tsx/ts` components, Layout files, global style configs (`tailwind.config.*`, `index.css`, CSS Module files, `components.json`).
- **EXCLUDE**: Third-party UI library source (shadcn/ui `components/ui/`), `node_modules/`, build output, lock files.
- **MUST BE READ ONLY**: No add, modify, or delete operations on the codebase during audit. Search and read only. (Writing the final DESIGN.md is the only allowed write.)

## Step 1: Concurrent Codebase Audit

Dispatch parallel sub-agents (or parallel tool calls) for each dimension:

| Sub-agent | Responsibility | Key Files to Inspect |
|-----------|---------------|---------------------|
| Visual | Color tokens, typography scale, spacing/shadow system | `tailwind.config.*`, `globals.css`/`index.css`, CSS variables, theme config |
| Layout | Container patterns, responsive breakpoints, high-density UI patterns | Layout components, page-level `tsx`, grid/flex patterns |
| Component | Splitting logic, state passing, reuse conventions | Business components in `src/`, shared hooks, context providers |
| Styling | Tailwind composition habits, dynamic class handling, override patterns | All business `tsx` files — className patterns, `cva`/`cn()` usage, conditional classes |

Each sub-agent should report findings with **concrete code examples** from the repo, not speculation.

## Step 2: Generate DESIGN.md

Create `DESIGN.md` in project root with these sections:

```markdown
# DESIGN_SPEC

## Visual Identity
- Core color system (CSS variables, Tailwind theme extensions)
- Typography scale (font families, sizes, weights)
- Spacing & shadow engineering (token usage patterns)

## Layout Strategy
- Global container conventions
- Responsive breakpoint strategy
- High-density / complex UI layout patterns

## Component Paradigm
- Business component splitting logic
- State passing / data flow conventions
- Reuse standards (shared components, hooks, utils)

## Styling Rules
- Tailwind class composition habits
- Dynamic class handling (cn/cva/clsx patterns)
- Default style override best practices
```

**Critical**: Every statement must reference **actually observed** code patterns. No fabrication.

## Post-Generation Recommendation

After creating DESIGN.md, remind the user to add a directive in their project's AI coding assistant config (however they manage it) requiring that all frontend tasks must read DESIGN.md first to align with global design philosophy and Tailwind conventions.

## Constraints
- [READ_ONLY_MODE] [EXPLORE_MODE] — never modify source code during audit.
- Report concurrency task allocation and completion status transparently.
- All findings must be grounded in actual code — no invented design rules.
- If the project doesn't use shadcn or Tailwind CSS, note the deviation and adapt the output accordingly.
