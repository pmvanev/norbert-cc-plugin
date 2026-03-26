# Walking Skeleton — otel-setup-skill

Date: 2026-03-25
Author: Quinn (acceptance-designer)

---

## Purpose

This document specifies the minimum command content that proves the skeleton works. The walking skeleton answers one question: "Can a user accomplish their goal and see the result?"

For this feature the question is: **Can Alex run `/norbert:setup` and have the 5 OTel keys written into `~/.claude/settings.json` with a clear confirmation?**

The skeleton covers happy path only: read → check → write → report.

---

## Walking Skeleton Identification

Two walking skeletons serve this feature:

**Skeleton A (US-1)**: Alex configures OTel from a fresh state — the setup command reads, checks, writes, and reports.

**Skeleton B (US-3)**: Alex sees post-install guidance — CLAUDE.md surfaces in context and names the command.

Skeleton A is the primary skeleton. It must work before Skeleton B has meaning (CLAUDE.md references a command that must exist and function).

---

## Skeleton A: Minimum Command Content

The `commands/setup.md` file needs only enough logic to deliver the happy path. The skeleton does NOT need to handle conflicts, --force, or malformed JSON. Those are covered by focused scenarios after the skeleton passes.

### What the skeleton must do

1. Resolve `~` to the user's home directory
2. Read `~/.claude/settings.json`
3. Check each of the 5 OTel keys — on a clean slate, none are present
4. Write all 5 keys into the `env` block (creating the block if absent)
5. Preserve all pre-existing content in the file
6. Report each added key with a `+` prefix
7. Instruct the user to restart Claude Code

### Minimum observable outcomes (skeleton complete when all are true)

- [ ] `~/.claude/settings.json` contains all 5 OTel keys with exact Norbert values
- [ ] Pre-existing keys (`permissions`, `enabledPlugins`, other `env` vars) are unchanged
- [ ] Output shows `+` prefix for each of the 5 added keys
- [ ] Output contains a restart reminder

### What the skeleton explicitly defers

These capabilities are NOT required for the skeleton to pass. Add them one scenario at a time after the skeleton is green:

| Deferred capability | Scenario that drives it |
|---------------------|------------------------|
| Report "no changes needed" when already configured | S-05 |
| Detect and warn on conflicting values | S-11 |
| --force overwrite | S-14 |
| Bail on malformed JSON | S-07 |
| Bail on missing file | S-08 |
| Mixed +/= output | S-04 |

---

## Skeleton A: Content Outline for commands/setup.md

This outline describes what the command Markdown must instruct Claude to do. It is not the final command — the implementer will author the actual Markdown prose. This outline defines the logical skeleton.

```
COMMAND: /norbert:setup

STEP 1 — Locate the target file
  Resolve the user's home directory (use $HOME on Unix, %USERPROFILE% on Windows,
  or rely on ~ expansion if Claude Code resolves it).
  Target path: ~/.claude/settings.json

STEP 2 — Read the current content
  Read ~/.claude/settings.json using the Read tool.
  [Skeleton: assume the file exists and is valid JSON.
   Full implementation adds: bail if missing, bail if malformed.]

STEP 3 — Parse and inspect
  Identify whether an "env" object exists in the JSON.
  For each of the 5 canonical OTel keys, check if it is present in env:
    CLAUDE_CODE_ENABLE_TELEMETRY  → expected: "1"
    OTEL_METRICS_EXPORTER         → expected: "otlp"
    OTEL_LOGS_EXPORTER            → expected: "otlp"
    OTEL_EXPORTER_OTLP_PROTOCOL   → expected: "http/json"
    OTEL_EXPORTER_OTLP_ENDPOINT   → expected: "http://127.0.0.1:3748"
  [Skeleton: assume all keys are absent. Full implementation adds comparison logic.]

STEP 4 — Merge keys
  Add the 5 keys into the env object (create env if absent).
  Do not remove or modify any other key.
  Write the updated JSON back to ~/.claude/settings.json using the Edit tool.

STEP 5 — Report
  For each key that was added, print:    + KEY_NAME
  After listing all keys, print:
    "OTel configuration written. Restart Claude Code for changes to take effect."
  [Optional: mention that Claude Code created an automatic backup.]
```

---

## Skeleton B: Minimum CLAUDE.md Content

The `CLAUDE.md` skeleton needs only enough content to surface the setup command in context.

### What the skeleton must contain

1. One sentence identifying Norbert and why setup matters
2. The exact command: `/norbert:setup`
3. A note that Norbert must be running first

### Minimum observable outcomes (skeleton complete when all are true)

- [ ] `CLAUDE.md` exists at the plugin root
- [ ] `CLAUDE.md` contains the exact string `/norbert:setup`
- [ ] When the norbert plugin is active, the command name is visible in session context

### Content outline for CLAUDE.md

```markdown
## Norbert OTel Setup

Norbert requires OTel environment variables in your Claude Code settings to receive telemetry.

Run `/norbert:setup` to configure them automatically. Norbert must be running on port 3748 first.
```

This is 3 lines of user-visible content — well within the 10-line constraint.

---

## Skeleton Litmus Test

Before handing off to the implementer, verify each skeleton passes this test:

| Question | Skeleton A | Skeleton B |
|----------|-----------|-----------|
| Title describes user goal, not technical flow? | "Alex configures OTel from a fresh state" — YES | "Alex sees setup instruction in context" — YES |
| Given/When describe user actions, not system state setup? | "Alex's settings.json contains valid JSON / Alex runs the command" — YES | "Alex opens a new session" — YES |
| Then describes user observations, not internal side effects? | "Keys are written, output lists them, restart reminder shown" — YES (user reads output and file) | "Alex sees note in context with /norbert:setup" — YES |
| Non-technical stakeholder can confirm "yes, that is what users need"? | YES — stakeholder can verify: "did the command add the right env vars?" | YES — stakeholder can verify: "does the plugin tell users what to do?" |

Both skeletons pass the litmus test.

---

## Implementation Entry Point

The implementer should start here:

1. Create `commands/setup.md` with the Skeleton A outline above as the logic specification
2. Verify S-01 manual validation steps pass (see test-scenarios.md)
3. Create `CLAUDE.md` with the Skeleton B outline
4. Verify S-16 manual validation steps pass (see test-scenarios.md)
5. Mark both skeleton scenarios complete, then proceed to S-02 through S-18 one at a time

Do not attempt to implement conflict detection, --force handling, or error paths before both skeletons pass. The skeletons define "done enough to be useful" — the focused scenarios define "done completely."
