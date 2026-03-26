# Component Boundaries — otel-setup-skill

Feature: Norbert OTel Setup Command and Post-Install Guidance
Date: 2026-03-25

---

## Components

### 1. commands/setup.md

| Property | Value |
|----------|-------|
| File path | `commands/setup.md` (plugin root-relative) |
| Invocation | `/norbert:setup` (Claude Code resolves plugin namespace `norbert` + filename `setup`) |
| Arguments | `$ARGUMENTS` — receives `--force` when supplied by user |
| Runtime | Claude Code — Claude reads the file and executes instructions via built-in Read, Edit, Bash tools |
| Owns | All logic for reading, comparing, merging, and reporting on `~/.claude/settings.json` env vars |
| Does NOT own | The target file itself; plugin-local `settings.json`; Norbert app startup |

**Boundary rules**:
- Reads only `~/.claude/settings.json` (user-level) — not the plugin-local `settings.json`
- Writes only to the `env` object within `~/.claude/settings.json`
- Touches only the 5 canonical OTel keys — all other keys (including other env vars) are read-preserved
- Produces no side effects beyond the settings file write and stdout reporting
- Terminates without write on: malformed JSON, any key conflict (without --force)

**Output protocol**:

| Prefix | Meaning |
|--------|---------|
| `+` | Key added (was absent) |
| `=` | Key already correct (no write) |
| `!` | Key overwritten (--force path) |

**Integration point**: `$ARGUMENTS` provides the raw string after the command name. The instruction must check whether `--force` appears in `$ARGUMENTS`.

---

### 2. CLAUDE.md

| Property | Value |
|----------|-------|
| File path | `CLAUDE.md` (plugin root — same level as `.claude-plugin/`, `hooks/`, `.mcp.json`) |
| Loading mechanism | Claude Code loads CLAUDE.md from plugin root automatically into session context when plugin is enabled |
| Owns | Post-install next-step guidance messaging |
| Does NOT own | Setup logic, settings.json interaction, Norbert app management |

**Boundary rules**:
- Content must be fewer than 10 lines of user-visible text
- Must contain the exact string `/norbert:setup` (matches `commands/setup.md` → `/norbert:setup`)
- Must not reproduce README content
- Must not use `companyAnnouncements` or any other mechanism — CLAUDE.md file presence is the mechanism
- Must state that Norbert must be running before setup has effect

**Consistency constraint**: The command name in CLAUDE.md (`/norbert:setup`) is derived from the filename `setup.md` in `commands/`. If the command file is ever renamed, CLAUDE.md must be updated synchronously.

---

### 3. settings.json (plugin root) — Existing, No Change

| Property | Value |
|----------|-------|
| File path | `settings.json` (plugin root) |
| Current content | The 5 OTel env vars |
| Status | Retained as-is — no deletion, no modification |
| Functional role | None for OTel env activation — silently ignored by Claude Code for this purpose |
| Documentation role | Serves as in-repo reference for the canonical OTel values |

**Boundary rules**:
- This file is NOT modified by this feature
- README.md must note that this file is not the activation target — it does not activate OTel
- The `/norbert:setup` command must never read or write this file

---

### 4. ~/.claude/settings.json — External Target

| Property | Value |
|----------|-------|
| Location | User's home directory: `~/.claude/settings.json` |
| Owned by | Claude Code (user-level configuration) |
| Modified by | `commands/setup.md` (via Claude's Edit tool) |
| Structure | JSON object; `env` key is a JSON object of string key-value pairs |

**Boundary rules**:
- `~` must be resolved to OS home (`$HOME` on Unix; `%USERPROFILE%` on Windows)
- Absent file: bail and instruct user to create `{}` or restart Claude Code (which creates it)
- Malformed JSON: bail with human-readable error — do not attempt repair
- Merge is surgical: only the 5 target keys are touched; all sibling keys and non-target env vars are preserved
- Claude Code creates timestamped backups automatically before writes (up to 5 retained) — no additional backup logic needed in the command

---

## Dependency Map

```
CLAUDE.md
  └── references --> /norbert:setup
                         |
                    commands/setup.md
                         |
                    reads/writes --> ~/.claude/settings.json
                                         (env block: 5 OTel keys)
```

**No circular dependencies. No shared mutable state between components.**

---

## What Is Out of Scope

| Item | Reason |
|------|--------|
| Norbert app installation | Separate concern; README covers it |
| Verifying Norbert is reachable on port 3748 | Not a settings concern; network state is runtime, not config |
| Uninstall cleanup of OTel vars | Out of scope for this feature; no lifecycle hook available |
| Automatic env var activation without restart | Claude Code constraint — env vars in settings.json take effect at next session start only |
| Backing up settings.json manually | Claude Code auto-backup covers this; redundant |
