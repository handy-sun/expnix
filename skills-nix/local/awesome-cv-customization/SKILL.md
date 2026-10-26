---
name: awesome-cv-customization
description: Customize the Awesome-CV LaTeX resume/CV template — fonts, sizes, colors, layout. Use when modifying the awesome-cv.cls class file or the user's sunqi-resume.tex document.
tags: [latex, cv, resume, fonts, typography, awesome-cv]
triggers:
  - User asks to change fonts, font sizes, or typography in their CV/resume
  - User asks to adjust colors, layout, or margins in awesome-cv
  - User asks to add new sections or modify CV structure
  - Any modification to awesome-cv.cls or examples/*.tex
---

# Awesome-CV Customization

The user maintains a fork of [posquit0/Awesome-CV](https://github.com/posquit0/Awesome-CV) at `~/work/awes-resume-tex`. The main class file is `awesome-cv.cls`. The user's personal resume is `examples/sunqi-resume.tex` (uses LuaLaTeX with `luatexja-fontspec` for Chinese support).

## Font Architecture (awesome-cv.cls)

### Font Definitions (lines ~84-117)

Three font families are defined via fontspec:

```latex
\setmainfont{Avenir Next}[...]   % Body/paragraph text (sffamily)
\setsansfont{Avenir Next}[...]   % Same as main (both map to sffamily)
\newfontfamily\roboto{Avenir Next}[...]  % Header font (different base weight)
```

**Pitfall: `\roboto` is NOT Roboto.** Despite the variable name, `\roboto` is now Avenir Next with Medium as the base weight. The name is kept for backward compatibility with all `\headerfont*` commands that reference it. Do NOT rename the variable — it's used throughout the cls.

### Font Weight Registration

Register extra FontFace variants to enable `\fontseries{...}` switching:

| Series code | Weight         | Usage                        |
|-------------|----------------|------------------------------|
| `l`         | Ultra Light    | `\headerfontlight` (name)    |
| (default)   | Regular        | Body text                    |
| `m`         | Medium         | `\roboto` base (headers)     |
| `sb`        | Demi Bold      | `\roboto\bfseries`           |
| `b`         | Bold           | `\bodyfont\bfseries`         |
| `h`         | Heavy          | Available but unused currently |

### Font Role Commands (lines ~196-200)

| Command              | Font chain                        | Purpose              |
|----------------------|-----------------------------------|----------------------|
| `\headerfont`        | `\roboto\selectfont`              | Header text (Medium) |
| `\headerfontlight`   | `\roboto\fontseries{l}\selectfont`| First name (Ultra Light) |
| `\footerfont`        | `\sffamily`                       | Footer text          |
| `\bodyfont`          | `\sffamily`                       | Body/entry text      |
| `\bodyfontlight`     | `\sffamily\fontseries{l}\selectfont` | Light body text  |

## Font Size Hierarchy

All sizes use `\fontsize{Xpt}{1em}` format. Current values (after 2026-04-30 bump):

### Header
- Name (first/last): 32pt — kept large, unchanged
- Position: 9pt (was 7.6pt)
- Address: 9pt (was 8pt)
- Social info: 8.5pt (was 6.8pt)
- Quote: 10pt (was 9pt)

### Structure
- Section title: 17pt bold (was 16pt)
- Subsection title: 13pt scshape (was 12pt)
- Paragraph body: 10pt light (was 9pt)
- Footer: 9pt scshape (was 8pt)

### Entry (experience, education)
- Title: 11pt bold (was 10pt)
- Position: 9pt scshape (was 8pt)
- Date: 9pt light slshape (was 8pt)
- Location: 10pt light slshape (was 9pt)
- Description: 10pt light (was 9pt)

### Subentry
- Title: 9pt (was 8pt)
- Position/Date/Location: 8pt (was 7pt)
- Description: 9pt (was 8pt)

### Honor & Skill
- Honor elements: 10pt (was 9pt)
- Skill type: 11pt bold (was 10pt)
- Skill set: 10pt light (was 9pt)

### Cover Letter
- Section title: 15pt bold (was 14pt)

## Changing Fonts — Procedure

1. **Check system font availability first**: `fc-list | grep -i 'FontName'`. Do NOT assume a font is installed.
2. **Update all three font definitions** (`\setmainfont`, `\setsansfont`, `\newfontfamily\roboto`).
3. **Register FontFace variants** that you'll use in style commands. At minimum register `l` (light) — it's used by `\headerfontlight` and `\bodyfontlight`.
4. **If changing header font weight**, update the `\roboto` definition's `UprightFont` (currently `* Medium`).
5. **Test with `lualatex`**: the user's resume uses LuaLaTeX, not XeLaTeX.

## macOS Font Alternatives

Pre-installed fonts that work well for CVs:

| Font            | Style                | Weights available                    |
|-----------------|----------------------|--------------------------------------|
| Avenir Next     | Elegant, modern      | Ultra Light → Heavy (8 weights)      |
| Helvetica Neue  | Classic, clean       | Thin → Black (9 weights)             |
| Optima          | Humanist, refined    | Regular, Medium, Bold                |
| Gill Sans       | British elegance     | Light → Bold                         |
| SF Pro          | Apple system font    | Ultra Light → Heavy                  |

**Pitfall: Source Sans 3 is NOT pre-installed on macOS.** The original template uses it, but it must be installed separately (via Homebrew: `brew install --cask font-source-sans-3`). If compiling fails with "font not found", this is likely the cause.

## Chinese Font Support

`examples/sunqi-resume.tex` uses:
```latex
\usepackage{luatexja-fontspec}
\setmainjfont{Songti SC}
\setsansjfont{Heiti SC}
```
These are macOS built-in CJK fonts. Changing the main font does NOT affect CJK — those are configured separately.

## Colors

Theme color is set in `examples/sunqi-resume.tex`:
```latex
\colorlet{awesome}{awesome-red}
```
Available: awesome-emerald, awesome-skyblue, awesome-red, awesome-pink, awesome-orange, awesome-nephritis, awesome-concrete, awesome-darknight. Custom: `\definecolor{awesome}{HTML}{RRGGBB}`.

## Compilation

```bash
# User's resume
lualatex -output-directory=examples examples/sunqi-resume.tex

# All examples
make

# Clean
make clean
```
