# Journey: OTel Setup — Visual Map

## Feature: otel-setup-skill

---

## Phase 1: JTBD Analysis

### Persona: Alex Chen

Alex is a developer who has just installed the norbert-cc-plugin into Claude Code. They want Norbert's observability data to flow properly — seeing tool use, session events, and AI behavior in Norbert's local dashboard. Alex is technically fluent but does not want to spend 20 minutes spelunking JSON files just to wire up a plugin they installed in two commands.

### Job Story 1: Connect Norbert to OTel

When I have just installed the norbert plugin and want to start collecting telemetry,
I want to run a single command that wires up the required environment variables,
so I can trust that Norbert is actually receiving data without manually editing settings files.

**Functional Job**: Merge 5 OTel environment variables into `~/.claude/settings.json` safely.

**Emotional Job**: Feel confident that setup is correct and complete — not nagging doubt that "maybe I missed something."

**Social Job**: Be the kind of developer who ships observable systems, not broken integrations no one notices until production.

### Job Story 2: Protect Existing OTel Configuration

When I already have OTel environment variables configured (perhaps for a different collector),
I want to be warned before any values are overwritten,
so I can choose consciously rather than discover data loss after the fact.

**Functional Job**: Detect key conflicts and surface them explicitly before writing.
**Emotional Job**: Feel in control — no silent surprises.
**Social Job**: Operate like a professional who respects existing infrastructure.

### Job Story 3: Know What to Do After Install

When I have just installed the norbert plugin but have not run setup,
I want to be clearly told that OTel configuration is required and exactly how to do it,
so I do not waste time wondering why no data appears in Norbert's dashboard.

**Functional Job**: Surface actionable next-step instructions at the right moment.
**Emotional Job**: Feel guided, not abandoned.
**Social Job**: Have a frictionless first experience that matches the plugin's professional quality.

---

### Four Forces Analysis

#### Job 1 — Connect Norbert to OTel

**Push (frustration with current state)**
- settings.json in the plugin root has the OTel env vars but they are silently ignored by Claude Code
- No error, no warning — data just does not flow to Norbert
- User has no way to know something is wrong without deep doc-diving

**Pull (attraction to the new solution)**
- One command: `/norbert:setup`
- Idempotent: safe to re-run anytime
- Immediate confirmation of success with visible variable names

**Anxiety (fears about the new)**
- "Will it overwrite things I already configured in settings.json?"
- "What if my settings.json is malformed — will it corrupt the file?"
- "Is this reversible?"

**Design implication**: The command must be explicitly non-destructive. Show what was written. Confirm the backup that Claude Code auto-creates. Bail cleanly on malformed JSON.

#### Job 2 — Protect Existing Configuration

**Push**: Silent overwrites of critical infrastructure config are devastating.
**Pull**: Explicit warnings give the user agency to decide.
**Anxiety**: "What if the warning is a false alarm and I have to figure out the right value myself?"
**Habit**: Developers expect tools that touch config files to be conservative and verbose.

**Design implication**: Warn per-key with old value vs. new value. Do not write any of the 5 keys if ANY conflict exists — require explicit user action (re-run with `--force` flag or manual edit). Never silent.

#### Job 3 — Know What to Do After Install

**Push**: Plugin README is read once at install time, then forgotten.
**Pull**: In-context guidance (surfaced when Claude Code loads) is impossible to miss.
**Anxiety**: "Maybe CLAUDE.md content gets stale or clutters my context window."
**Habit**: Developers expect plugins to "just work" — a required post-install manual step is friction.

**Design implication**: CLAUDE.md in plugin root is the right mechanism. It surfaces in context automatically when the plugin is loaded, survives across sessions, and is easy to remove or extend. SessionStart hook would fire on every session (annoying). README is forgotten. `companyAnnouncements` is not a documented Claude Code plugin key.

---

## Phase 2: Journey Map

### Emotional Arc

```
   ANXIETY             FOCUSED              CONFIDENT
     |                    |                     |
     |  "Did it install   |  "OK, I run         |  "Variables set,
     |   right? Why is    |   /norbert:setup"   |   Norbert is live"
     |   nothing showing  |                     |
     |   in Norbert?"     |                     |
     |                    |                     |
[INSTALL] ---------> [DISCOVER] -----------> [SETUP] -----------> [VERIFY]
   ^                     ^                     ^                     ^
   |                     |                     |                     |
Norbert plugin     CLAUDE.md in           Command runs          Telemetry
installed via      context shows          safely, writes        flows to
/plugin install    next-step note         env block             localhost:3748
```

**Arc type**: Confidence Building — Anxious/Uncertain → Focused/Engaged → Confident/Satisfied

---

## Phase 3: Journey Steps with TUI Mockups

### Step 1: Plugin Installed — First Session Opens

**Trigger**: Alex runs `/plugin install norbert@pmvanev-plugins`

**What Alex sees in context** (CLAUDE.md from plugin is loaded automatically):

```
+-- Norbert Plugin — Post-Install Note --------------------------------+
|                                                                      |
|  Norbert is installed. One more step required for telemetry.        |
|                                                                      |
|  Run this command to configure OpenTelemetry in your               |
|  ~/.claude/settings.json:                                           |
|                                                                      |
|    /norbert:setup                                                    |
|                                                                      |
|  This merges 5 OTel environment variables into your user            |
|  settings. Without this step, hooks fire but no telemetry           |
|  reaches Norbert's dashboard.                                        |
|                                                                      |
+----------------------------------------------------------------------+
```

**Emotional state**:
- Entry: Mildly anxious ("is it working?")
- Exit: Informed and directed ("I know what to do")

---

### Step 2: Alex Runs `/norbert:setup` — Happy Path

**Precondition**: `~/.claude/settings.json` exists with no `env` block (or env block has no OTel keys)

**TUI mockup — happy path output**:

```
+-- /norbert:setup -------------------------------------------------------+
|                                                                          |
|  Reading ~/.claude/settings.json ... OK                                  |
|                                                                          |
|  No existing OTel keys found. Writing 5 variables:                       |
|                                                                          |
|    + CLAUDE_CODE_ENABLE_TELEMETRY    = 1                                 |
|    + OTEL_METRICS_EXPORTER          = otlp                               |
|    + OTEL_LOGS_EXPORTER             = otlp                               |
|    + OTEL_EXPORTER_OTLP_PROTOCOL   = http/json                           |
|    + OTEL_EXPORTER_OTLP_ENDPOINT   = http://127.0.0.1:3748               |
|                                                                          |
|  All other existing keys preserved.                                      |
|                                                                          |
|  Settings written to ~/.claude/settings.json                             |
|  Note: Claude Code creates a timestamped backup automatically.           |
|                                                                          |
|  OTel configuration complete. Restart Claude Code to apply.             |
|                                                                          |
+--------------------------------------------------------------------------+
```

**Emotional state**:
- Entry: Curious/focused
- Exit: Confident — explicit confirmation with visible values

---

### Step 3: Alex Runs `/norbert:setup` — Idempotent Path

**Precondition**: All 5 keys already set with correct values

**TUI mockup — already configured**:

```
+-- /norbert:setup -------------------------------------------------------+
|                                                                          |
|  Reading ~/.claude/settings.json ... OK                                  |
|                                                                          |
|  All 5 OTel keys already set with correct values:                        |
|                                                                          |
|    = CLAUDE_CODE_ENABLE_TELEMETRY    = 1                                 |
|    = OTEL_METRICS_EXPORTER          = otlp                               |
|    = OTEL_LOGS_EXPORTER             = otlp                               |
|    = OTEL_EXPORTER_OTLP_PROTOCOL   = http/json                           |
|    = OTEL_EXPORTER_OTLP_ENDPOINT   = http://127.0.0.1:3748               |
|                                                                          |
|  No changes made. OTel is already configured correctly.                  |
|                                                                          |
+--------------------------------------------------------------------------+
```

**Emotional state**:
- Entry: Returning user, rechecking setup
- Exit: Reassured — explicit "already correct" is better than silence

---

### Step 4: Alex Runs `/norbert:setup` — Conflict Path

**Precondition**: One or more of the 5 keys exist with different values (e.g., OTEL_EXPORTER_OTLP_ENDPOINT points to a different collector)

**TUI mockup — conflict warning**:

```
+-- /norbert:setup -------------------------------------------------------+
|                                                                          |
|  Reading ~/.claude/settings.json ... OK                                  |
|                                                                          |
|  WARNING: 1 existing key has a different value:                          |
|                                                                          |
|    ! OTEL_EXPORTER_OTLP_ENDPOINT                                         |
|        current value:  http://my-otel-collector:4318                     |
|        norbert value:  http://127.0.0.1:3748                             |
|                                                                          |
|  No changes were made.                                                   |
|                                                                          |
|  To overwrite all conflicting keys with Norbert's values:               |
|    /norbert:setup --force                                                |
|                                                                          |
|  To update settings.json manually before re-running:                    |
|    Edit ~/.claude/settings.json and remove conflicting keys.             |
|                                                                          |
+--------------------------------------------------------------------------+
```

**Emotional state**:
- Entry: Confident (expecting happy path)
- Exit: Controlled — warned before damage, given clear options

---

### Step 5: Alex Runs `/norbert:setup` — Malformed JSON

**Precondition**: `~/.claude/settings.json` contains invalid JSON

**TUI mockup — bail on bad JSON**:

```
+-- /norbert:setup -------------------------------------------------------+
|                                                                          |
|  Reading ~/.claude/settings.json ... ERROR                               |
|                                                                          |
|  Cannot parse ~/.claude/settings.json as valid JSON.                     |
|  No changes were made.                                                   |
|                                                                          |
|  To investigate:                                                         |
|    1. Open ~/.claude/settings.json in an editor                          |
|    2. Validate JSON at: https://jsonlint.com                             |
|    3. Re-run /norbert:setup after fixing                                 |
|                                                                          |
|  If settings.json is missing, Claude Code will create it automatically  |
|  on next restart. You can also create an empty file:                     |
|    echo '{}' > ~/.claude/settings.json                                   |
|                                                                          |
+--------------------------------------------------------------------------+
```

**Emotional state**:
- Entry: Trying to fix a broken state
- Exit: Guided — clear recovery steps, no data corruption

---

## Phase 4: Integration Checkpoints

### Shared Artifacts

| Artifact | Source | Consumers | Risk |
|---|---|---|---|
| `~/.claude/settings.json` | User's Claude Code config | `/norbert:setup` reads/writes; Claude Code reads on start | HIGH — wrong path = silent failure |
| `env` block in settings.json | Read by Claude Code runtime | 5 OTel vars flow to all Claude Code processes | HIGH — missing = no telemetry |
| 5 OTel key names | Norbert feature spec | `commands/setup.md`, journey scenarios, BDD tests | HIGH — typo = silent failure |
| CLAUDE.md post-install note | Plugin root CLAUDE.md | Loaded by Claude Code into context automatically | MEDIUM — content must stay accurate |

### Integration Checkpoint: settings.json Path

The path `~/.claude/settings.json` must expand correctly on Windows, macOS, and Linux. The command implementation must resolve `~` to the actual home directory — not use a literal `~` string in JSON writes.

### Integration Checkpoint: Env Block Merge (not replace)

The merge operation must:
1. Read existing `settings.json`
2. Navigate to or create `env` key (object, not array)
3. Set only the 5 target keys — leave all other keys under `env` and all sibling keys untouched
4. Write back valid JSON

This is a surgical merge, not a file replace.

### Integration Checkpoint: Claude Code OTel Activation

Claude Code reads `env` from `~/.claude/settings.json` at session start. Changes take effect only after restart. The command output must communicate this explicitly so Alex does not expect immediate effect.

---

## Mechanism Decision: Post-Install Messaging

### Options Evaluated

| Mechanism | Supported? | Fires When? | Persistent? | Verdict |
|---|---|---|---|---|
| CLAUDE.md in plugin root | YES — confirmed by nwave-marketplace and official plugin docs | Automatically loaded into context when plugin is enabled | Permanent (until removed) | **RECOMMENDED** |
| `companyAnnouncements` in plugin settings.json | NOT DOCUMENTED — no reference in any official plugin structure docs | Unknown | Unknown | Rejected |
| SessionStart hook with echo | YES — supported | Every session start | Every session (noisy) | Rejected — wrong frequency |
| README only | YES — but passive | Only when user reads README | No | Rejected — too weak |

### Decision: CLAUDE.md in Plugin Root

A `CLAUDE.md` file at the plugin root is loaded by Claude Code automatically as context for every session where the plugin is enabled. This is the same mechanism used by the nwave-marketplace plugin and confirmed by the official `plugin-structure` skill documentation.

**Why this works**:
- Surfaces the next-step instruction in context — impossible to miss
- Survives across sessions (unlike a one-time install message)
- The developer can remove it or update it as the plugin matures
- No code required — pure content
- Does not fire repeatedly in an annoying loop

**What it must contain** (minimal):
- One-line statement that OTel setup is required
- The exact command: `/norbert:setup`
- One-line explanation of what it does (builds trust)
- Link to README for more detail

**What it must NOT contain**:
- Long prose that clutters context
- Setup instructions (belongs in README, not repeated here)
- Technical implementation details
