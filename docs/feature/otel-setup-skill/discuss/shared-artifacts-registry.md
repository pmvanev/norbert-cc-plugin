# Shared Artifacts Registry — otel-setup-skill

## Feature: otel-setup-skill
## Journey: OTel Setup for Norbert Plugin

---

## Registry

### settings_json_path

| Field | Value |
|-------|-------|
| Canonical value | `~/.claude/settings.json` (resolves to OS home directory + `.claude/settings.json`) |
| Source of truth | Claude Code user settings specification |
| Owner | otel-setup-skill / `/norbert:setup` command |
| Integration risk | HIGH — pointing at the plugin-local `settings.json` (which is silently ignored by Claude Code for env vars) is the exact bug this feature fixes |
| Validation | Read at command start; bail if not found or not valid JSON; write only on success |
| Consumers | Step 2 (read + write), Step 3 (read only), Step 4 (read only), Step 5 (read, bail) |

**Known trap**: The norbert plugin has a `settings.json` at its own root with the 5 OTel vars. That file is NOT the target. The target is `~/.claude/settings.json` at user level. Any implementation must resolve `~` to the actual home directory — not hardcode a path and not use the plugin-local file.

---

### otel_env_keys

| Field | Value |
|-------|-------|
| Canonical keys and values | See table below |
| Source of truth | Norbert feature spec and OTel + Claude Code documentation |
| Owner | otel-setup-skill |
| Integration risk | HIGH — key name typo or wrong value = silent OTel failure |
| Validation | Key names and values must match exactly in command output, BDD scenarios, and implementation |
| Consumers | Step 2 (write), Step 3 (compare), Step 4 (compare and warn), `journey-otel-setup.feature`, all user stories |

| Key | Value |
|-----|-------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` |
| `OTEL_METRICS_EXPORTER` | `otlp` |
| `OTEL_LOGS_EXPORTER` | `otlp` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/json` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://127.0.0.1:3748` |

---

### plugin_claude_md

| Field | Value |
|-------|-------|
| Canonical location | `norbert-cc-plugin/CLAUDE.md` (plugin root, not `.claude-plugin/`) |
| Source of truth | Plugin repository |
| Owner | otel-setup-skill (content), plugin maintainer (file) |
| Integration risk | MEDIUM — content must reference `/norbert:setup` with the exact command name as registered |
| Validation | Command name in CLAUDE.md must match the filename in `commands/setup.md` |
| Consumers | Step 1 (Claude Code loads into context), users reading context |

---

### norbert_setup_command_name

| Field | Value |
|-------|-------|
| Canonical value | `/norbert:setup` |
| Source of truth | `commands/setup.md` filename in the plugin's commands directory |
| Owner | otel-setup-skill |
| Integration risk | HIGH — name mismatch between CLAUDE.md reference and actual registered command = user types command and gets "not found" |
| Validation | Filename `setup.md` in `commands/` → registered as `/norbert:setup`. CLAUDE.md must reference this exact string. |
| Consumers | CLAUDE.md (Step 1), US-3 acceptance criteria, BDD scenarios |

---

## Integration Checkpoint Summary

| Checkpoint | Risk | What to Verify |
|---|---|---|
| settings_json_path resolves to user home | HIGH | `~` expands correctly on Windows (`%USERPROFILE%`), macOS/Linux (`$HOME`) |
| env block merge is surgical | HIGH | Only 5 target keys modified; all other content preserved byte-for-byte |
| Restart required for env changes | MEDIUM | Command output explicitly states "restart Claude Code to apply" |
| CLAUDE.md command name matches registration | HIGH | `setup.md` filename → `/norbert:setup`; CLAUDE.md must say `/norbert:setup` |
| settings.json in plugin root is NOT the target | HIGH | Do not confuse `norbert-cc-plugin/settings.json` with `~/.claude/settings.json` |
| No raw stack traces in error output | MEDIUM | JSON parse errors shown in human language with recovery steps |

---

## Dependency: Claude Code Auto-Backup

Claude Code creates timestamped backups of settings files before writes. This is a documented safety net. The `/norbert:setup` command output should mention this backup exists — it reduces anxiety for users who are worried about data loss. The command does not need to create its own backup.
