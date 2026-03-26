# Test Scenarios — otel-setup-skill

Date: 2026-03-25
Author: Quinn (acceptance-designer)
Source: docs/feature/otel-setup-skill/discuss/journey-otel-setup.feature
Framework: Manual validation (no automated runner — deliverables are Markdown files, runtime is Claude)

---

## Overview

This document maps each user story to its acceptance scenarios, provides implementation sequence guidance, and supplies manual validation steps for each scenario. Because the deliverable is a Markdown command file (`commands/setup.md`) executed by Claude, there is no test runner. Each scenario is validated by a human executing the command under the described conditions and observing the output.

**Total scenarios: 18**
- Walking skeletons: 2
- Happy path (focused): 4
- Error/conflict path: 8
- Idempotent/edge case: 2
- Property-invariant: 2

Error path ratio: 10/18 = **56%** (above 40% target)

---

## Implementation Sequence

Tackle scenarios in this order. Mark each complete before moving to the next.

| # | Scenario | Story | Category | Priority |
|---|----------|-------|----------|----------|
| 1 | Happy path: fresh install, no env block | US-1 | Walking skeleton | FIRST — proves the skeleton works |
| 2 | CLAUDE.md appears in context | US-3 | Walking skeleton | SECOND — proves post-install guidance works |
| 3 | Setup creates env block when none exists | US-1 | Happy path | 3rd |
| 4 | Output distinguishes + from = in mixed run | US-1 | Edge case | 4th |
| 5 | All 5 keys already correct — idempotent | US-1 | Idempotent | 5th |
| 6 | Setup is safe to run multiple times | US-1 | Idempotent | 6th |
| 7 | Preserves unrelated env vars | US-1 | Happy path | 7th |
| 8 | Single conflicting key — warn, no write | US-2 | Error path | 8th |
| 9 | Multiple conflicting keys — all warned | US-2 | Error path | 9th |
| 10 | Partially correct — per-key discrimination | US-2 | Error path | 10th |
| 11 | --force overwrites conflicting keys | US-2 | Error path | 11th |
| 12 | Malformed JSON — bail, no write | US-1 | Error path | 12th |
| 13 | settings.json does not exist — bail, instruct | US-1 | Error path | 13th |
| 14 | CLAUDE.md is concise and action-oriented | US-3 | Happy path | 14th |
| 15 | CLAUDE.md command name matches registered command | US-3 | Happy path | 15th |
| 16 | @property: setup preserves all non-OTel content | US-1 | Property | 16th |
| 17 | @property: setup is safe to run at any time | US-1/2 | Property | 17th |
| 18 | Alex returns to project — CLAUDE.md still reminds | US-3 | Happy path | 18th |

---

## US-1 Scenarios: One-Command OTel Configuration

---

### S-01: Alex configures OTel from a completely fresh state

**Category**: Walking skeleton
**Story**: US-1
**Walking skeleton**: YES — this is the primary skeleton. Proves the complete read → check → write → report journey.

```gherkin
@walking_skeleton
Scenario: Alex runs setup with no existing OTel configuration
  Given Alex's ~/.claude/settings.json contains valid JSON
  And the env block in ~/.claude/settings.json has none of the 5 OTel keys
  When Alex runs "/norbert:setup"
  Then the command reports "No existing OTel keys found"
  And all 5 OTel keys are written into the env block of ~/.claude/settings.json
  And all other keys in ~/.claude/settings.json are unchanged
  And the output lists each key with a "+" prefix indicating it was added
  And the output instructs Alex to restart Claude Code for changes to take effect
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"permissions": {}, "enabledPlugins": ["norbert"]}` — valid JSON, no env block.
2. Run `/norbert:setup` in a Claude Code session with the norbert plugin active.
3. Verify output contains the text "No existing OTel keys found" or equivalent summary.
4. Verify output lists all 5 keys each preceded by `+`:
   - `+ CLAUDE_CODE_ENABLE_TELEMETRY`
   - `+ OTEL_METRICS_EXPORTER`
   - `+ OTEL_LOGS_EXPORTER`
   - `+ OTEL_EXPORTER_OTLP_PROTOCOL`
   - `+ OTEL_EXPORTER_OTLP_ENDPOINT`
5. Verify output includes instruction to restart Claude Code.
6. Read `~/.claude/settings.json` and confirm:
   - `env.CLAUDE_CODE_ENABLE_TELEMETRY` = `"1"`
   - `env.OTEL_METRICS_EXPORTER` = `"otlp"`
   - `env.OTEL_LOGS_EXPORTER` = `"otlp"`
   - `env.OTEL_EXPORTER_OTLP_PROTOCOL` = `"http/json"`
   - `env.OTEL_EXPORTER_OTLP_ENDPOINT` = `"http://127.0.0.1:3748"`
7. Verify `permissions` and `enabledPlugins` keys are still present with original values.

**Done when**: All 5 keys present with exact values. All pre-existing keys preserved. Output shows `+` prefix and restart reminder.

---

### S-02: Setup creates an env block when settings.json has none

**Category**: Happy path
**Story**: US-1

```gherkin
Scenario: Alex runs setup when settings.json has no env block at all
  Given Alex's ~/.claude/settings.json contains valid JSON with no env key
  When Alex runs "/norbert:setup"
  Then the command creates an env block in ~/.claude/settings.json
  And all 5 OTel keys are written into the new env block
  And all pre-existing top-level keys are preserved
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"permissions": {"allow": []}}` — no `env` key at all.
2. Run `/norbert:setup`.
3. Read `~/.claude/settings.json` and confirm an `env` key now exists at the top level.
4. Confirm all 5 OTel keys are present inside `env` with exact values (see S-01 step 6).
5. Confirm `permissions` key is unchanged.
6. Confirm the file is valid JSON (no syntax errors).

---

### S-03: Setup preserves unrelated env vars alongside OTel keys

**Category**: Happy path
**Story**: US-1

```gherkin
Scenario: Alex runs setup when settings.json has an env block with unrelated keys
  Given Alex's ~/.claude/settings.json has an env block containing "MY_TOKEN=abc123"
  And none of the 5 OTel keys are in the env block
  When Alex runs "/norbert:setup"
  Then all 5 OTel keys are added to the env block
  And MY_TOKEN=abc123 remains in the env block unchanged
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"MY_TOKEN": "abc123"}}`.
2. Run `/norbert:setup`.
3. Read `~/.claude/settings.json` and confirm `env.MY_TOKEN` = `"abc123"` (unchanged).
4. Confirm all 5 OTel keys are present with exact values.
5. Confirm no other keys were modified.

---

### S-04: Output distinguishes newly added keys from already-correct keys in the same run

**Category**: Edge case (Gap 3 from acceptance review)
**Story**: US-1

```gherkin
Scenario: Alex runs setup when some OTel keys are already correct and some are missing
  Given Alex's ~/.claude/settings.json has CLAUDE_CODE_ENABLE_TELEMETRY set to "1"
  And OTEL_METRICS_EXPORTER set to "otlp"
  And the remaining 3 OTel keys are absent
  When Alex runs "/norbert:setup"
  Then the output shows CLAUDE_CODE_ENABLE_TELEMETRY with a "=" prefix
  And the output shows OTEL_METRICS_EXPORTER with a "=" prefix
  And the output shows the 3 missing keys each with a "+" prefix
  And all 5 OTel keys are present in ~/.claude/settings.json with correct values
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"CLAUDE_CODE_ENABLE_TELEMETRY": "1", "OTEL_METRICS_EXPORTER": "otlp"}}`.
2. Run `/norbert:setup`.
3. Verify output shows `= CLAUDE_CODE_ENABLE_TELEMETRY` and `= OTEL_METRICS_EXPORTER`.
4. Verify output shows `+ OTEL_LOGS_EXPORTER`, `+ OTEL_EXPORTER_OTLP_PROTOCOL`, `+ OTEL_EXPORTER_OTLP_ENDPOINT`.
5. Read file and confirm all 5 keys present with correct values.
6. Verify the 2 pre-existing correct keys were NOT re-written (their values are the same and no unnecessary write occurred).

---

### S-05: Alex runs setup and all 5 keys are already correct

**Category**: Idempotent path
**Story**: US-1

```gherkin
Scenario: Alex runs setup when all 5 OTel keys are already correct
  Given Alex's ~/.claude/settings.json contains all 5 OTel keys with correct values
  When Alex runs "/norbert:setup"
  Then the command reports "No changes made. OTel is already configured correctly."
  And the output lists all 5 keys with a "=" prefix indicating existing correct values
  And ~/.claude/settings.json is not modified
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with all 5 OTel keys at their correct Norbert values.
2. Record a hash or timestamp of the file.
3. Run `/norbert:setup`.
4. Verify output contains "No changes made" or equivalent.
5. Verify output lists all 5 keys with `=` prefix.
6. Verify file hash/timestamp is unchanged (no write occurred).

---

### S-06: Setup is safe to run multiple times without accumulating duplicates

**Category**: Idempotent path
**Story**: US-1

```gherkin
Scenario: Alex runs setup multiple times safely
  Given Alex has already run "/norbert:setup" successfully
  When Alex runs "/norbert:setup" again
  Then the command completes without error
  And no duplicate keys are created in ~/.claude/settings.json
  And the output confirms no changes were needed
```

**Manual validation steps**:
1. Run `/norbert:setup` on a clean settings.json (confirms first run succeeds).
2. Run `/norbert:setup` again without modifying the file.
3. Verify output reports no changes needed.
4. Read `~/.claude/settings.json` and verify each of the 5 OTel keys appears exactly once.
5. Confirm the file is valid JSON.

---

### S-07: Malformed settings.json causes bail with human-readable error

**Category**: Error path
**Story**: US-1

```gherkin
Scenario: Alex runs setup with a malformed settings.json
  Given Alex's ~/.claude/settings.json contains invalid JSON (e.g., trailing comma)
  When Alex runs "/norbert:setup"
  Then the command reports "Cannot parse ~/.claude/settings.json as valid JSON"
  And no changes are written to ~/.claude/settings.json
  And the output provides recovery steps including a JSON validator URL
  And the output does not expose a raw stack trace
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"MY_TOKEN": "abc",}}` — trailing comma, invalid JSON.
2. Record file content hash.
3. Run `/norbert:setup`.
4. Verify output contains message about inability to parse the file as valid JSON.
5. Verify output mentions recovery steps (e.g., "use jsonlint.com" or similar).
6. Verify output does NOT contain raw error stack trace or internal error object.
7. Verify file content hash is unchanged (no write occurred).

---

### S-08: settings.json does not exist — bail and instruct

**Category**: Error path
**Story**: US-1

```gherkin
Scenario: Alex runs setup when settings.json does not exist
  Given ~/.claude/settings.json does not exist
  When Alex runs "/norbert:setup"
  Then the command reports that settings.json was not found
  And the output shows how to create an empty settings.json
  And no file is created automatically
```

**Manual validation steps**:
1. Temporarily rename or remove `~/.claude/settings.json` (back it up first).
2. Run `/norbert:setup`.
3. Verify output reports that the file was not found.
4. Verify output provides instructions for creating the file (e.g., "create an empty `{}` file at `~/.claude/settings.json`" or "restart Claude Code to have it created automatically").
5. Verify `~/.claude/settings.json` does NOT now exist (command did not auto-create it).
6. Restore the backup file.

---

### S-09 @property: Setup preserves all non-OTel content in settings.json

**Category**: Property invariant
**Story**: US-1
**Tag**: @property — signals implementer to verify this invariant holds across varied pre-existing content

```gherkin
@property
Scenario: Setup command preserves all non-OTel content in settings.json
  Given ~/.claude/settings.json contains permissions, enabledPlugins, and env with other keys
  When "/norbert:setup" writes the 5 OTel keys
  Then every key outside the 5 OTel target keys is byte-for-byte identical to before the write
```

**Manual validation steps**:
1. Prepare a rich `~/.claude/settings.json`:
   ```json
   {
     "permissions": {"allow": ["Bash", "Read"], "deny": []},
     "enabledPlugins": ["norbert", "my-other-plugin"],
     "env": {
       "MY_CUSTOM_VAR": "hello-world",
       "ANOTHER_VAR": "12345"
     }
   }
   ```
2. Record the exact content of every non-OTel key.
3. Run `/norbert:setup`.
4. Read the file and verify:
   - `permissions.allow` = `["Bash", "Read"]` (unchanged)
   - `permissions.deny` = `[]` (unchanged)
   - `enabledPlugins` = `["norbert", "my-other-plugin"]` (unchanged)
   - `env.MY_CUSTOM_VAR` = `"hello-world"` (unchanged)
   - `env.ANOTHER_VAR` = `"12345"` (unchanged)
5. Confirm all 5 OTel keys are now present with correct values.
6. Repeat with 3+ different pre-existing configurations to validate the invariant holds broadly.

---

### S-10 @property: Setup is safe to run at any time without corrupting settings

**Category**: Property invariant
**Story**: US-1/2
**Tag**: @property

```gherkin
@property
Scenario: Setup command is safe to run at any time without side effects
  Given Alex runs "/norbert:setup" any number of times in any order
  Then ~/.claude/settings.json always ends in a valid JSON state
  And the OTel keys always have the correct Norbert values after "--force" or a clean run
  And non-OTel settings are never modified
```

**Manual validation steps**:
1. Run `/norbert:setup` 5 times in succession on the same file.
2. After each run, verify the file is valid JSON.
3. After all runs, verify all 5 OTel keys have correct Norbert values.
4. Verify no non-OTel keys were modified.
5. Run `/norbert:setup --force` twice in succession and repeat verification.

---

## US-2 Scenarios: Conflict Warning for Existing OTel Configuration

---

### S-11: Single conflicting key triggers warning and no write

**Category**: Error path
**Story**: US-2

```gherkin
Scenario: Alex runs setup when one OTel key exists with a different value
  Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
  When Alex runs "/norbert:setup"
  Then the command reports a warning for OTEL_EXPORTER_OTLP_ENDPOINT
  And the warning shows the current value "http://my-otel-collector:4318"
  And the warning shows Norbert's intended value "http://127.0.0.1:3748"
  And no changes are written to ~/.claude/settings.json
  And the output instructs Alex to run "/norbert:setup --force" to overwrite
  And the output instructs Alex to edit ~/.claude/settings.json manually as an alternative
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"OTEL_EXPORTER_OTLP_ENDPOINT": "http://my-otel-collector:4318"}}`.
2. Record file hash.
3. Run `/norbert:setup`.
4. Verify output contains a warning referencing `OTEL_EXPORTER_OTLP_ENDPOINT`.
5. Verify warning shows current value `http://my-otel-collector:4318`.
6. Verify warning shows Norbert's intended value `http://127.0.0.1:3748`.
7. Verify output mentions `/norbert:setup --force` as the override option.
8. Verify output mentions manual edit as an alternative.
9. Verify file hash is unchanged (no write occurred).

---

### S-12: Multiple conflicting keys all appear in warning

**Category**: Error path
**Story**: US-2

```gherkin
Scenario: Alex runs setup with multiple conflicting OTel keys
  Given Alex's ~/.claude/settings.json has 3 of the 5 OTel keys with different values
  When Alex runs "/norbert:setup"
  Then the command reports warnings for all 3 conflicting keys
  And each warning shows the current value and Norbert's intended value
  And no changes are written to ~/.claude/settings.json
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with:
   - `OTEL_METRICS_EXPORTER` = `"prometheus"` (conflicts)
   - `OTEL_LOGS_EXPORTER` = `"console"` (conflicts)
   - `OTEL_EXPORTER_OTLP_ENDPOINT` = `"http://corporate:4318"` (conflicts)
2. Record file hash.
3. Run `/norbert:setup`.
4. Verify output contains a warning entry for each of the 3 conflicting keys.
5. Verify each warning entry shows the current value and Norbert's intended value.
6. Verify file hash is unchanged.

---

### S-13: Partially correct config — per-key discrimination

**Category**: Error path
**Story**: US-2

```gherkin
Scenario: Alex has one key with correct value and one with a different value
  Given Alex's ~/.claude/settings.json has CLAUDE_CODE_ENABLE_TELEMETRY set to "1"
  And OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
  When Alex runs "/norbert:setup"
  Then only OTEL_EXPORTER_OTLP_ENDPOINT is flagged as a conflict
  And CLAUDE_CODE_ENABLE_TELEMETRY is reported as already correct
  And no changes are written to ~/.claude/settings.json
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"CLAUDE_CODE_ENABLE_TELEMETRY": "1", "OTEL_EXPORTER_OTLP_ENDPOINT": "http://my-otel-collector:4318"}}`.
2. Record file hash.
3. Run `/norbert:setup`.
4. Verify output flags `OTEL_EXPORTER_OTLP_ENDPOINT` as a conflict.
5. Verify output shows `CLAUDE_CODE_ENABLE_TELEMETRY` as already correct (e.g., with `=` prefix or "already set" language).
6. Verify file hash is unchanged.

---

### S-14: --force overwrites conflicting keys with confirmation

**Category**: Error path
**Story**: US-2

```gherkin
Scenario: Alex uses --force to overwrite conflicting keys
  Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
  When Alex runs "/norbert:setup --force"
  Then all 5 OTel keys are written with Norbert's values
  And the output lists each overwritten key with a "!" prefix indicating it was replaced
  And the output confirms Alex's previous values were replaced
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"OTEL_EXPORTER_OTLP_ENDPOINT": "http://my-otel-collector:4318"}}`.
2. Run `/norbert:setup --force`.
3. Verify output lists `OTEL_EXPORTER_OTLP_ENDPOINT` with `!` prefix (overwritten).
4. Verify output mentions that previous values were replaced.
5. Read `~/.claude/settings.json` and confirm:
   - `env.OTEL_EXPORTER_OTLP_ENDPOINT` = `"http://127.0.0.1:3748"` (Norbert's value)
   - All other 4 OTel keys present with correct Norbert values.

---

### S-15: Conflict blocks entire write — non-conflicting keys are not partially written

**Category**: Error path
**Story**: US-2

```gherkin
Scenario: Conflict prevents any keys from being written including non-conflicting ones
  Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
  And the other 4 OTel keys are absent from ~/.claude/settings.json
  When Alex runs "/norbert:setup"
  Then the command reports a conflict for OTEL_EXPORTER_OTLP_ENDPOINT
  And the 4 absent OTel keys are NOT written to ~/.claude/settings.json
  And ~/.claude/settings.json is not modified
```

**Manual validation steps**:
1. Prepare `~/.claude/settings.json` with `{"env": {"OTEL_EXPORTER_OTLP_ENDPOINT": "http://my-otel-collector:4318"}}`.
2. Record file hash.
3. Run `/norbert:setup`.
4. Verify output reports conflict for `OTEL_EXPORTER_OTLP_ENDPOINT`.
5. Read `~/.claude/settings.json` and confirm `CLAUDE_CODE_ENABLE_TELEMETRY`, `OTEL_METRICS_EXPORTER`, `OTEL_LOGS_EXPORTER`, and `OTEL_EXPORTER_OTLP_PROTOCOL` are all absent (not partially written).
6. Verify file hash is unchanged.

**Rationale**: This is the "all-or-nothing on clean runs" constraint from US-2 acceptance criteria. It is distinct from S-11 (single conflict) — S-15 verifies that the 4 absent keys are not silently added while the 1 conflict is blocked.

---

## US-3 Scenarios: Post-Install Next Steps Guidance

---

### S-16: Alex sees setup instruction in context after installing norbert

**Category**: Walking skeleton
**Story**: US-3
**Walking skeleton**: YES — proves the post-install guidance path works end-to-end.

```gherkin
@walking_skeleton
Scenario: Alex sees setup instruction in context after installing norbert
  Given Alex has installed the norbert plugin via "/plugin install norbert@pmvanev-plugins"
  And CLAUDE.md exists at the plugin root with setup instructions
  When Alex opens a new Claude Code session
  Then Alex sees a note in context stating OTel setup is required
  And the note includes the exact command "/norbert:setup"
  And the note explains that the command configures ~/.claude/settings.json
```

**Manual validation steps**:
1. Ensure the norbert plugin is installed and enabled.
2. Verify `CLAUDE.md` exists at the plugin root (same directory as `.claude-plugin/`, `hooks/`, `.mcp.json`).
3. Open a new Claude Code session (or `/clear` to reset context).
4. Ask Claude: "What do I need to do to set up Norbert?" — verify Claude references `/norbert:setup`.
5. Alternatively, inspect the session context at session start for CLAUDE.md content.
6. Verify the CLAUDE.md content includes `/norbert:setup`.
7. Verify the content explains the purpose: configuring OTel in `~/.claude/settings.json`.

---

### S-17: CLAUDE.md content is concise and action-oriented

**Category**: Happy path
**Story**: US-3

```gherkin
Scenario: CLAUDE.md content is concise and action-oriented
  Given the norbert plugin is enabled
  When Claude Code loads the plugin's CLAUDE.md into context
  Then the CLAUDE.md content is fewer than 10 lines
  And it contains the command "/norbert:setup"
  And it does not duplicate the full README content
```

**Manual validation steps**:
1. Open `CLAUDE.md` at the plugin root.
2. Count the number of non-blank lines of user-visible content. Verify fewer than 10.
3. Verify the text `/norbert:setup` is present.
4. Verify the content does not reproduce paragraphs from `README.md`.
5. Verify the content does not use the `companyAnnouncements` JSON key mechanism (it is a plain Markdown file, not a settings entry).

---

### S-18: CLAUDE.md command name matches the registered command

**Category**: Happy path
**Story**: US-3

```gherkin
Scenario: CLAUDE.md command name matches the registered command
  Given "commands/setup.md" is the file defining the setup command
  And the setup command is registered as "/norbert:setup"
  When CLAUDE.md references the next-step command
  Then CLAUDE.md contains the string "/norbert:setup"
  And running "/norbert:setup" as shown in CLAUDE.md succeeds
```

**Manual validation steps**:
1. Verify `commands/setup.md` exists at the plugin root.
2. Open `CLAUDE.md` and confirm it contains the exact string `/norbert:setup` (not `/norbert:Setup` or `/setup` or any variation).
3. Run `/norbert:setup` in an active Claude Code session and confirm it executes (does not return "command not found").
4. Note: the command name derives from the filename — `setup.md` → `setup` → `/norbert:setup`. If the file is ever renamed, this scenario will fail and CLAUDE.md must be updated synchronously.

---

## Manual Validation Notes

### Platform coverage

Run S-01 (walking skeleton) on both Unix (macOS/Linux) and Windows to validate `~` expansion:
- Unix: `~` must resolve to `$HOME`
- Windows: `~` must resolve to `%USERPROFILE%`

This is not a separate scenario (tilde expansion is an implementation detail), but it must be verified during acceptance of S-01.

### settings.json backup behavior

Claude Code creates timestamped backups before writes. During S-01 manual validation, check that a backup file appears in `~/.claude/` alongside the modified `settings.json`. The command output may optionally mention this as a safety note — if mentioned, verify it is accurate.

### CLAUDE.md mechanism constraint

The CLAUDE.md file must exist as a file at the plugin root. It must NOT be implemented as:
- A `companyAnnouncements` entry in `settings.json`
- A `SessionStart` hook echo
- Any mechanism other than the CLAUDE.md file itself

This is a content-inspection check, not a behavioral scenario. Verify by opening the plugin directory and confirming the file is present and is a plain Markdown file.
