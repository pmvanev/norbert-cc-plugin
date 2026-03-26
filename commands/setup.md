# /norbert:setup

Configure OpenTelemetry for Norbert by merging 5 environment variables into the user-level Claude Code settings file (`~/.claude/settings.json`). This command is idempotent and surgical — it only touches the 5 Norbert OTel keys and leaves everything else unchanged.

---

## Canonical OTel Keys

The 5 keys this command manages (exact names and values):

| Key | Value |
|-----|-------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `"1"` |
| `OTEL_METRICS_EXPORTER` | `"otlp"` |
| `OTEL_LOGS_EXPORTER` | `"otlp"` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `"http/json"` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `"http://127.0.0.1:3748"` |

---

## Instructions

Follow these steps in order. Do not skip steps. Do not write to the file unless all checks pass.

### Step 1 — Resolve the target file path

Determine the user's home directory:
- On Unix/macOS: use `$HOME`
- On Windows: use `%USERPROFILE%`

The target file is: `{home}/.claude/settings.json`

Use the Bash tool to resolve the path:
```bash
echo "$HOME/.claude/settings.json"
```
On Windows:
```bash
echo "$USERPROFILE/.claude/settings.json"
```

Store the resolved path as `SETTINGS_PATH`. All subsequent reads and writes use this path.

### Step 2 — Check whether the file exists

Use the Bash tool to check whether `SETTINGS_PATH` exists:
```bash
test -f "$SETTINGS_PATH" && echo "EXISTS" || echo "MISSING"
```

**If the file does not exist**: do NOT create it automatically. Stop and show the missing-file message (see the "Missing File" section below).

**If the file exists**: continue to Step 3.

### Step 3 — Read the file

Use the Read tool to read the contents of `SETTINGS_PATH`.

If the Read tool returns an empty file or an unreadable result, treat it as a missing-file condition and go to the "Missing File" section.

### Step 4 — Parse JSON

Attempt to parse the file content as JSON.

**If parsing fails** (invalid JSON, trailing commas, unclosed brackets, etc.): stop immediately and show the malformed-JSON message (see the "Malformed JSON" section below). Do NOT write anything to the file.

**If parsing succeeds**: continue to Step 5.

### Step 5 — Inspect the current state

Check each of the 5 canonical keys in the `env` object of the parsed JSON.

For each key, determine its status:
- **MISSING**: the key does not exist in `env` (or `env` does not exist)
- **CORRECT**: the key exists and its value exactly matches the canonical value (string equality)
- **CONFLICT**: the key exists and its value differs from the canonical value

Record the status of all 5 keys before deciding what to do.

Also check whether `$ARGUMENTS` contains `--force`. Store this as `FORCE_MODE` (true or false).

### Step 6 — Decide and act

**Case A — All 5 keys are CORRECT (and no MISSING keys)**

No write needed. Report each key with `=` prefix and state "Already configured — no changes made."

Example output:
```
= CLAUDE_CODE_ENABLE_TELEMETRY
= OTEL_METRICS_EXPORTER
= OTEL_LOGS_EXPORTER
= OTEL_EXPORTER_OTLP_PROTOCOL
= OTEL_EXPORTER_OTLP_ENDPOINT

Already configured — no changes made.
```

Stop. Do not write to the file.

---

**Case B — At least one key is MISSING and no key is a CONFLICT**

Merge the missing keys into the `env` block. If `env` does not exist, create it as an empty object first. Do not modify any other key anywhere in the file.

Write the updated JSON back to `SETTINGS_PATH` using the Edit tool. Use proper JSON formatting (2-space indent is fine).

Note: Claude Code automatically creates a timestamped backup of settings files before writes — your previous settings are safe.

Report each key with its prefix:
- `+` for newly added keys
- `=` for keys that were already correct

Then show the restart reminder:
```
Restart Claude Code for these settings to take effect.
```

Example output (3 missing, 2 already correct):
```
= CLAUDE_CODE_ENABLE_TELEMETRY
= OTEL_METRICS_EXPORTER
+ OTEL_LOGS_EXPORTER
+ OTEL_EXPORTER_OTLP_PROTOCOL
+ OTEL_EXPORTER_OTLP_ENDPOINT

OTel configuration written. Restart Claude Code for these settings to take effect.
Note: Claude Code created an automatic timestamped backup of your settings file.
```

---

**Case C — At least one key is a CONFLICT and FORCE_MODE is false**

Do NOT write anything to the file. Show a conflict warning for every CONFLICT key.

For each CONFLICT key, show:
```
CONFLICT: KEY_NAME
  Current value:  "current-value-here"
  Norbert value:  "norbert-canonical-value-here"
```

For CORRECT keys, show them with `=` prefix. For MISSING keys, show them as `(not set)`.

After listing all keys, show:
```
No changes written. Resolve the conflicts above, then re-run:
  /norbert:setup --force    — overwrite all 5 keys with Norbert's values
  Edit ~/.claude/settings.json manually — adjust individual keys yourself
```

Example output (1 conflict, 1 correct, 3 missing):
```
= CLAUDE_CODE_ENABLE_TELEMETRY

CONFLICT: OTEL_METRICS_EXPORTER
  Current value:  "prometheus"
  Norbert value:  "otlp"

  OTEL_LOGS_EXPORTER          (not set)
  OTEL_EXPORTER_OTLP_PROTOCOL (not set)
  OTEL_EXPORTER_OTLP_ENDPOINT (not set)

No changes written. Resolve the conflicts above, then re-run:
  /norbert:setup --force    — overwrite all 5 keys with Norbert's values
  Edit ~/.claude/settings.json manually — adjust individual keys yourself
```

---

**Case D — At least one key is a CONFLICT and FORCE_MODE is true**

Write all 5 canonical keys unconditionally, regardless of their current state. Overwrite any CONFLICT key with Norbert's canonical value. Keys that were already CORRECT are written with the same value (safe idempotent overwrite).

Write the updated JSON back to `SETTINGS_PATH` using the Edit tool.

Note: Claude Code automatically creates a timestamped backup of settings files before writes — your previous settings are safe.

Report each key with its prefix:
- `!` for keys that were overwritten (CONFLICT)
- `=` for keys that were already correct (CORRECT)
- `+` for keys that were missing (MISSING)

Then show the restart reminder:
```
Restart Claude Code for these settings to take effect.
```

Example output (1 overwritten, 1 correct, 3 added):
```
= CLAUDE_CODE_ENABLE_TELEMETRY
! OTEL_METRICS_EXPORTER        (overwritten: was "prometheus", now "otlp")
+ OTEL_LOGS_EXPORTER
+ OTEL_EXPORTER_OTLP_PROTOCOL
+ OTEL_EXPORTER_OTLP_ENDPOINT

OTel configuration written. Restart Claude Code for these settings to take effect.
Note: Claude Code created an automatic timestamped backup of your settings file.
```

---

## Missing File

Show this message when `~/.claude/settings.json` does not exist:

```
Cannot find ~/.claude/settings.json.

This file is created automatically by Claude Code on first launch. To create it manually and then re-run setup:

  echo '{}' > ~/.claude/settings.json

Then run /norbert:setup again.

Alternatively, restart Claude Code once — it will create the file — then run /norbert:setup.
```

Do not create the file automatically. Do not write any OTel keys.

---

## Malformed JSON

Show this message when `~/.claude/settings.json` exists but cannot be parsed as valid JSON:

```
Cannot parse ~/.claude/settings.json as valid JSON.

No changes were made to your settings file.

Recovery steps:
  1. Open ~/.claude/settings.json in a text editor.
  2. Paste the contents into https://jsonlint.com to identify the syntax error.
  3. Fix the error and save the file.
  4. Re-run /norbert:setup.
```

Do not attempt to repair or partially parse the file. Do not write anything. Leave the file byte-for-byte identical to what was read.

Do not show a raw exception message, stack trace, or internal error object in the output.
