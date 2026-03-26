<!-- markdownlint-disable MD024 -->
# User Stories — otel-setup-skill

Feature ID: otel-setup-skill
Feature: Norbert OTel Setup Command and Post-Install Guidance
Journey: `journey-otel-setup.yaml`

---

## US-1: One-Command OTel Configuration

### Problem

Alex is a developer who has installed the norbert-cc-plugin into Claude Code. They find it confusing to discover that the plugin's own `settings.json` silently does nothing for OTel — they must manually edit `~/.claude/settings.json` with 5 specific environment variable keys to get telemetry flowing to Norbert's dashboard. One wrong key name, one missed variable, and Norbert stays silent with no error.

### Who

- Developer who has just installed norbert-cc-plugin
- Context: first session after plugin install, Norbert desktop app is running on port 3748
- Motivation: wants Norbert to actually receive telemetry without spelunking JSON files

### Solution

A `/norbert:setup` command that reads `~/.claude/settings.json`, merges the 5 OTel environment variables safely, and reports exactly what was written. Idempotent: safe to re-run. Reads the existing file first; never replaces it wholesale.

### Domain Examples

#### 1: Alex — Fresh Install, No Existing OTel Config

Alex has just installed the plugin. Their `~/.claude/settings.json` has `permissions` and `enabledPlugins` keys but no `env` block. They run `/norbert:setup`. The command adds an `env` block with all 5 OTel keys, reports each key with a `+` prefix, and instructs them to restart Claude Code. Their `permissions` and `enabledPlugins` keys are untouched.

#### 2: Alex — Env Block Exists with Unrelated Keys

Alex has `MY_CUSTOM_VAR=hello` in their `env` block from a previous project. None of the 5 OTel keys are present. They run `/norbert:setup`. The command adds the 5 OTel keys alongside `MY_CUSTOM_VAR`. The output shows 5 lines with `+` prefix. `MY_CUSTOM_VAR` is not mentioned in output (unmodified) and remains in the file.

#### 3: Alex — Malformed settings.json

Alex's colleague accidentally left a trailing comma in `~/.claude/settings.json`. Alex runs `/norbert:setup`. The command reads the file, fails to parse it as JSON, outputs a human-readable error with recovery steps (open file, use jsonlint.com, re-run after fixing). The file is not touched. No stack trace is shown.

### UAT Scenarios (BDD)

#### Scenario: Setup adds all 5 OTel keys to a fresh settings.json

```gherkin
Given Alex's ~/.claude/settings.json is valid JSON with no env block
When Alex runs "/norbert:setup"
Then all 5 OTel keys appear in the env block of ~/.claude/settings.json
And all pre-existing keys in ~/.claude/settings.json are unchanged
And the command output lists each key with a "+" prefix
And the output instructs Alex to restart Claude Code
```

#### Scenario: Setup creates env block when one does not exist

```gherkin
Given Alex's ~/.claude/settings.json has no env key
When Alex runs "/norbert:setup"
Then ~/.claude/settings.json gains an env object containing all 5 OTel keys
And the overall structure of ~/.claude/settings.json remains valid JSON
```

#### Scenario: Setup preserves unrelated env vars

```gherkin
Given Alex's ~/.claude/settings.json env block contains "MY_TOKEN=abc123"
And none of the 5 OTel keys are present in the env block
When Alex runs "/norbert:setup"
Then MY_TOKEN=abc123 is still present in the env block after the command
And all 5 OTel keys are added alongside it
```

#### Scenario: Setup is idempotent when already configured

```gherkin
Given Alex's ~/.claude/settings.json contains all 5 OTel keys with correct values
When Alex runs "/norbert:setup"
Then ~/.claude/settings.json is not modified
And the output reports "No changes made. OTel is already configured correctly."
And the output lists all 5 keys with a "=" prefix
```

#### Scenario: Setup bails safely on malformed settings.json

```gherkin
Given Alex's ~/.claude/settings.json contains invalid JSON
When Alex runs "/norbert:setup"
Then ~/.claude/settings.json is not modified
And the output reports the file cannot be parsed as valid JSON
And the output provides recovery steps
And no raw stack trace is shown to Alex
```

### Acceptance Criteria

- [ ] All 5 OTel keys are written with exact names and values from the canonical list
- [ ] All other content in `~/.claude/settings.json` is preserved unchanged
- [ ] Command creates an `env` block if one does not exist
- [ ] Command output explicitly instructs restart for changes to take effect
- [ ] Malformed JSON results in bail with no file write and a human-readable error message
- [ ] Command is idempotent — multiple runs produce no duplicate keys and no error

### Technical Notes

- Target file: `~/.claude/settings.json` (user-level) — NOT the plugin-local `settings.json`
- `~` must be resolved to the OS home directory (`$HOME` on Unix, `%USERPROFILE%` on Windows)
- The `env` key in `~/.claude/settings.json` is a JSON object (key/value string pairs)
- Claude Code creates timestamped backups of settings files before writes — the command may mention this as a safety note
- The plugin-local `settings.json` has the same 5 vars but they are silently ignored for env — that file is not the target

### Dependencies

- US-3 (post-install messaging) — informs Alex that US-1 command exists and must be run
- Claude Code plugin command system (`commands/setup.md` auto-discovered)

---

## US-2: Conflict Warning for Existing OTel Configuration

### Problem

Alex is a returning developer with OTel already configured for a different collector (e.g., a corporate OTEL collector at `http://my-otel-collector:4318`). They find it unacceptable that running `/norbert:setup` silently overwrites their production telemetry endpoint. Without a warning, they would discover data loss only when their existing dashboards stop receiving data.

### Who

- Developer with existing OTel environment variables in `~/.claude/settings.json`
- Context: wants to try the Norbert plugin without breaking their existing observability stack
- Motivation: maintain control over which OTel keys get changed and when

### Solution

Before writing any of the 5 OTel keys, `/norbert:setup` compares the current value of each key with the intended Norbert value. If any key differs, it displays a per-key warning showing the current value and the intended Norbert value, writes nothing, and offers two explicit recovery paths: `--force` to overwrite or manual edit.

### Domain Examples

#### 1: Alex — One Conflicting Endpoint Key

Alex has `OTEL_EXPORTER_OTLP_ENDPOINT=http://my-otel-collector:4318` already set. They run `/norbert:setup`. The command displays the conflicting key with both the current and intended value. It writes nothing. It shows `--force` and the manual edit options. Alex decides to edit manually, adding a new Norbert endpoint alongside their existing one.

#### 2: Alex — Three Conflicting Keys

Alex has set `OTEL_METRICS_EXPORTER=prometheus`, `OTEL_LOGS_EXPORTER=console`, and `OTEL_EXPORTER_OTLP_ENDPOINT=http://corporate:4318`. They run `/norbert:setup`. All three conflicting keys appear in the warning output with current and intended values. The two correct keys (`CLAUDE_CODE_ENABLE_TELEMETRY` and `OTEL_EXPORTER_OTLP_PROTOCOL`) are shown as already correct. Nothing is written.

#### 3: Alex — Uses --force After Reviewing the Warning

Alex reviews the warning from Example 1, decides Norbert is the priority, and runs `/norbert:setup --force`. All 5 OTel keys are written with Norbert's values. Overwritten keys are shown with a `!` prefix indicating replacement. Alex can see clearly that their previous endpoint value was replaced.

### UAT Scenarios (BDD)

#### Scenario: Single conflicting key triggers warning and no write

```gherkin
Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
When Alex runs "/norbert:setup"
Then the command outputs a warning for OTEL_EXPORTER_OTLP_ENDPOINT
And the warning shows the current value "http://my-otel-collector:4318"
And the warning shows Norbert's value "http://127.0.0.1:3748"
And ~/.claude/settings.json is not modified
And the output instructs Alex to use "--force" or edit manually
```

#### Scenario: Multiple conflicting keys all appear in warning

```gherkin
Given Alex's ~/.claude/settings.json has 3 of the 5 OTel keys with different values
When Alex runs "/norbert:setup"
Then the output shows a warning entry for each of the 3 conflicting keys
And each warning entry shows the current value and Norbert's intended value
And ~/.claude/settings.json is not modified
```

#### Scenario: --force overwrites conflicting keys

```gherkin
Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
When Alex runs "/norbert:setup --force"
Then OTEL_EXPORTER_OTLP_ENDPOINT is updated to "http://127.0.0.1:3748" in ~/.claude/settings.json
And the output lists the overwritten key with a "!" prefix
And all other non-OTel keys remain unchanged
```

#### Scenario: Partially correct config is handled per-key

```gherkin
Given Alex's ~/.claude/settings.json has CLAUDE_CODE_ENABLE_TELEMETRY set to "1" (correct)
And OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318" (different)
When Alex runs "/norbert:setup"
Then OTEL_EXPORTER_OTLP_ENDPOINT is flagged as a conflict
And CLAUDE_CODE_ENABLE_TELEMETRY is reported as already correct (not flagged)
And ~/.claude/settings.json is not modified
```

### Acceptance Criteria

- [ ] Any key with a different existing value triggers a warning before any write
- [ ] Warning shows: key name, current value, intended Norbert value
- [ ] No write occurs when any key has a conflict (all-or-nothing on clean runs)
- [ ] `--force` flag writes all 5 keys regardless of conflicts and marks overwrites with `!`
- [ ] Keys already at the correct value are not flagged as conflicts

### Technical Notes

- Per-key comparison: string equality of current value vs. canonical Norbert value
- Conflict blocks the entire write — do not partially write the non-conflicting keys
- `--force` writes all 5 keys including any that were already correct (safe to overwrite with same value)

### Dependencies

- US-1 (base setup command) — conflict detection is a branch within the same command
- Shared artifact: `otel_env_keys` canonical list (from `shared-artifacts-registry.md`)

---

## US-3: Post-Install Next Steps Guidance

### Problem

Alex is a plugin user who has just installed norbert-cc-plugin via the marketplace. They find the plugin README only visible during installation — once installed, there is no reminder that a required manual step (running `/norbert:setup`) is needed before telemetry works. Alex spends time troubleshooting empty Norbert dashboards before realizing the OTel environment variables were never set.

### Who

- Developer who has just installed the norbert-cc-plugin for the first time
- Context: first session after plugin install, may not have re-read the README
- Motivation: wants Norbert to work without needing to remember a post-install step

### Solution

A `CLAUDE.md` file at the norbert plugin root — automatically loaded by Claude Code into context whenever the plugin is active. Content is minimal: one statement that OTel setup is required, the exact command to run, and one sentence explaining what it does.

### Domain Examples

#### 1: Alex — First Session After Install

Alex installs the plugin and opens Claude Code. The CLAUDE.md from the norbert plugin appears in Claude's context. Alex or Claude reads it and sees the note about `/norbert:setup`. Alex runs the command and is set up in under a minute.

#### 2: Alex — Returns to Project After a Week

Alex installs the plugin on a Friday, gets distracted, and forgets to run setup. On Monday they open Claude Code and wonder why Norbert shows no data. The CLAUDE.md note is still in context, reminding them to run `/norbert:setup`. They run it and are immediately configured.

#### 3: Sam — Team Member Inherits the Plugin Config

Sam joins Alex's team. The norbert plugin is in the team's plugin list. Sam enables it and opens Claude Code. The CLAUDE.md note surfaces in their session automatically — Sam knows to run `/norbert:setup` without needing to be told separately.

### UAT Scenarios (BDD)

#### Scenario: CLAUDE.md appears in context after plugin install

```gherkin
Given the norbert-cc-plugin is enabled in Claude Code
And CLAUDE.md exists at the norbert plugin root
When Alex opens a new Claude Code session
Then CLAUDE.md content from the norbert plugin is present in the session context
And the content includes the command "/norbert:setup"
And the content explains that this command configures OTel for Norbert
```

#### Scenario: CLAUDE.md content is minimal and action-oriented

```gherkin
Given the norbert plugin's CLAUDE.md is loaded
When Claude Code presents the plugin context
Then the CLAUDE.md content is fewer than 10 lines
And it does not reproduce the full README
And it contains one clear action: run "/norbert:setup"
```

#### Scenario: CLAUDE.md command name matches the registered command

```gherkin
Given "commands/setup.md" is the file defining the setup command
And the setup command is registered as "/norbert:setup"
When CLAUDE.md references the next-step command
Then CLAUDE.md contains the string "/norbert:setup"
And running "/norbert:setup" as shown in CLAUDE.md succeeds
```

### Acceptance Criteria

- [ ] `CLAUDE.md` exists at the norbert plugin root (alongside `.claude-plugin/`, `hooks/`, `.mcp.json`)
- [ ] `CLAUDE.md` is fewer than 10 lines of user-visible content
- [ ] `CLAUDE.md` contains the exact string `/norbert:setup`
- [ ] The command name in `CLAUDE.md` matches the registered command (filename `setup.md` → `/norbert:setup`)
- [ ] `CLAUDE.md` does not use `companyAnnouncements` or any other mechanism — CLAUDE.md file at root is the mechanism

### Technical Notes

- Mechanism: CLAUDE.md at plugin root is automatically loaded into Claude Code context when the plugin is enabled. This is confirmed by official plugin-structure documentation and observed in multiple installed plugins (nwave-marketplace, pmvanev-plugins/phil).
- `companyAnnouncements` key in plugin settings.json is not documented in Claude Code plugin specs — do not use.
- SessionStart hook echo approach was rejected: fires on every session (annoying) and requires stdout-to-user path that is not guaranteed.
- README-only approach was rejected: too passive, read once and forgotten.
- If the plugin team later adds a CLI-level post-install lifecycle hook, CLAUDE.md can be retired. For now it is the most reliable and lowest-friction option.

### Dependencies

- US-1 (the command CLAUDE.md references must exist)
- Plugin command system: `commands/setup.md` must be present for `/norbert:setup` to be available
