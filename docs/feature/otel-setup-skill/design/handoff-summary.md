# Handoff Summary — otel-setup-skill Design Wave

To: acceptance-designer (DISTILL wave)
From: Morgan (solution-architect)
Date: 2026-03-25
Reviewer: skipped per des-config.json (reviewer_model: skip)

---

## Feature

Norbert OTel Setup Command and Post-Install Guidance (`otel-setup-skill`)

Two new plugin artifacts:
1. `commands/setup.md` — Markdown instruction file for `/norbert:setup` command
2. `CLAUDE.md` — Post-install context note at plugin root

One documentation update:
3. `README.md` — Add setup section, clarify plugin-local settings.json trap

---

## Design Artifacts Produced

| Artifact | Path |
|----------|------|
| Architecture design | `docs/feature/otel-setup-skill/design/architecture-design.md` |
| Component boundaries | `docs/feature/otel-setup-skill/design/component-boundaries.md` |
| Implementation roadmap | `docs/feature/otel-setup-skill/design/roadmap.json` |
| ADR-001: Command vs Skill | `docs/adrs/ADR-001-command-vs-skill.md` |
| ADR-002: Post-install messaging | `docs/adrs/ADR-002-post-install-messaging-mechanism.md` |
| ADR-003: Plugin-local settings.json | `docs/adrs/ADR-003-plugin-local-settings-json-disposition.md` |

---

## Key Decisions (Summary)

| Decision | Choice | ADR |
|----------|--------|-----|
| Command vs Skill | `commands/setup.md` (simple command) — one-shot, user-direct, no agent-composition need | ADR-001 |
| Post-install messaging | `CLAUDE.md` at plugin root — confirmed supported, auto-loaded by Claude Code | ADR-002 |
| Plugin-local settings.json | Leave as-is — add README note clarifying it does not activate OTel | ADR-003 |

---

## Implementation Scope

| File | Action |
|------|--------|
| `CLAUDE.md` | Create new |
| `commands/setup.md` | Create new |
| `README.md` | Update — add setup section |
| `settings.json` (plugin root) | No change |

**Step ratio**: 4 steps / 3 production files = 1.33 (limit: 2.5) — PASS

---

## Critical Constraints for Acceptance Designer

1. **Target file**: `~/.claude/settings.json` — NOT the plugin-local `settings.json`. This distinction is the core bug this feature fixes.
2. **Canonical OTel keys**: 5 keys with exact names and values from `shared-artifacts-registry.md`. Any typo = silent OTel failure.
3. **~ expansion**: Must resolve to OS home directory. Command instructions must handle both Unix (`$HOME`) and Windows (`%USERPROFILE%`).
4. **Merge semantics**: Surgical — only the 5 target keys are written. All other content in settings.json is preserved exactly.
5. **All-or-nothing write**: If any key conflicts (without --force), write nothing. No partial writes.
6. **CLAUDE.md command name**: Must contain `/norbert:setup` exactly — derived from `commands/setup.md` filename.
7. **Content length**: CLAUDE.md must be fewer than 10 lines of user-visible content.

---

## Output Prefix Convention (for acceptance scenarios)

| Prefix | Meaning | Path |
|--------|---------|------|
| `+` | Key added (was absent) | Happy path |
| `=` | Key already correct (no write) | Idempotent path |
| `!` | Key overwritten (--force) | Force path |

---

## Canonical OTel Keys (from shared-artifacts-registry.md)

| Key | Value |
|-----|-------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` |
| `OTEL_METRICS_EXPORTER` | `otlp` |
| `OTEL_LOGS_EXPORTER` | `otlp` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/json` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://127.0.0.1:3748` |

---

## Quality Gates Passed

- [x] Requirements traced to components (US-1, US-2, US-3 → commands/setup.md, CLAUDE.md)
- [x] Component boundaries defined with clear responsibilities
- [x] Technology choices in ADRs with 2+ alternatives each
- [x] Quality attributes addressed (safety, idempotency, usability, discoverability, maintainability, cross-platform)
- [x] C4 diagrams produced (L1 System Context + L2 Container)
- [x] OSS preference: N/A — no technology selection required (Markdown files, Claude is runtime)
- [x] Roadmap step ratio: 1.33 (limit 2.5) — PASS
- [x] AC are behavioral, not implementation-coupled
- [x] Rejected simpler alternatives documented (2 alternatives)
- [x] Peer review: skipped per des-config.json (reviewer_model: skip)
