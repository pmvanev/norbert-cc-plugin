# Acceptance Review — otel-setup-skill

Date: 2026-03-25
Reviewer: Quinn (acceptance-designer)
Source Gherkin: docs/feature/otel-setup-skill/discuss/journey-otel-setup.feature

---

## Gap Analysis: DISCUSS Gherkin vs. Acceptance Criteria

### US-1: One-Command OTel Configuration

Acceptance criteria from user-stories.md vs. scenario coverage:

| AC Item | Covered by Scenario | Status |
|---------|---------------------|--------|
| All 5 OTel keys written with exact names and values | "Alex runs setup with no existing OTel configuration" | COVERED |
| All other content in settings.json preserved unchanged | "Alex runs setup with no existing OTel configuration" + @property preservation scenario | COVERED |
| Command creates an env block if one does not exist | "Alex runs setup when settings.json has no env block at all" | COVERED |
| Command output explicitly instructs restart | "Alex runs setup with no existing OTel configuration" (Then: output instructs restart) | COVERED |
| Malformed JSON results in bail with no write and human-readable error | "Alex runs setup with a malformed settings.json" | COVERED |
| Command is idempotent — multiple runs produce no duplicate keys | "Alex runs setup when all 5 OTel keys are already correct" + "Alex runs setup multiple times safely" | COVERED |

**US-1 verdict: FULLY COVERED**

---

### US-2: Conflict Warning for Existing OTel Configuration

| AC Item | Covered by Scenario | Status |
|---------|---------------------|--------|
| Any key with a different existing value triggers warning before any write | "Alex runs setup when one OTel key exists with a different value" | COVERED |
| Warning shows: key name, current value, intended Norbert value | "Alex runs setup when one OTel key exists with a different value" | COVERED |
| No write occurs when any key has a conflict (all-or-nothing on clean runs) | "Alex runs setup when one OTel key exists with a different value" + multiple conflict scenario | COVERED |
| --force flag writes all 5 keys and marks overwrites with ! | "Alex uses --force to overwrite conflicting keys" | COVERED |
| Keys already at correct value are not flagged as conflicts | "Alex has one key with correct value and one with a different value" | COVERED |

**US-2 verdict: FULLY COVERED**

---

### US-3: Post-Install Next Steps Guidance

| AC Item | Covered by Scenario | Status |
|---------|---------------------|--------|
| CLAUDE.md exists at the norbert plugin root | "Alex sees setup instruction in context after installing norbert" | COVERED |
| CLAUDE.md is fewer than 10 lines of user-visible content | "CLAUDE.md content is concise and action-oriented" | COVERED |
| CLAUDE.md contains the exact string /norbert:setup | Both US-3 scenarios | COVERED |
| Command name in CLAUDE.md matches the registered command | Implicit in "Alex sees setup instruction" scenario + command-name consistency scenario in user-stories.md | COVERED |
| CLAUDE.md does not use companyAnnouncements or any other mechanism | Not explicitly tested — see gap below | GAP |

**US-3 verdict: ONE GAP (low severity)**

---

## Gaps Identified

### Gap 1: Missing file scenario — settings.json does not exist (Severity: LOW)

**What the task brief requires**: "Missing file — ~/.claude/settings.json does not exist → created with env block only"

**What the DISCUSS Gherkin has**: "Alex runs setup when settings.json does not exist" — this scenario correctly captures the bail-and-instruct behavior. However, the scenario states "no file is created automatically" and "shows how to create an empty settings.json." This matches the architecture design (bail + instruct) but the brief description says "created with env block only" — a direct contradiction.

**Resolution**: The architecture design (component-boundaries.md) is authoritative: "Absent file: bail and instruct user to create {} or restart Claude Code (which creates it)." The DISCUSS scenario correctly captures this. The brief's description "created with env block only" is a phrasing error in the task brief, not a gap in coverage. The existing scenario is correct.

**Action required**: None — scenario is correctly specified.

---

### Gap 2: CLAUDE.md mechanism verification (Severity: LOW)

**What is missing**: No scenario verifies that CLAUDE.md does NOT use companyAnnouncements or another mechanism. This is a constraint in the acceptance criteria ("CLAUDE.md does not use companyAnnouncements or any other mechanism").

**Assessment**: This is a content-inspection criterion (verifiable by reading the file), not a behavioral scenario. It is appropriately captured as a manual validation checklist item rather than a Gherkin scenario. Adding a Gherkin scenario for "file does not use mechanism X" would be testing the absence of an implementation detail — a business language violation.

**Action required**: Add as a manual validation checklist item in test-scenarios.md. No new Gherkin scenario needed.

---

### Gap 3: Output prefix characters not explicitly verified in all paths (Severity: LOW)

**What is covered**: The `+` prefix is verified in the happy path scenario. The `=` prefix is verified in the idempotent scenario. The `!` prefix is verified in the --force scenario.

**What is not covered**: When partial keys are added (some already correct, some new), the output should show `=` for existing-correct keys and `+` for newly added keys in the same run. The existing scenario "Alex runs setup when settings.json has an env block with unrelated keys" covers adding all 5 keys but does not cover a mixed `+`/`=` output scenario.

**Assessment**: This is a meaningful gap. The output prefix contract is part of the observable outcome for the user (they need to understand what happened per-key).

**Action required**: Add one focused scenario: "Output distinguishes newly added keys from already-correct keys in the same run." See test-scenarios.md for the proposed scenario text.

---

### Gap 4: Cross-platform tilde expansion (Severity: LOW)

**What is missing**: No scenario verifies that `~` resolves to the correct home directory on Windows vs. Unix.

**Assessment**: This is a valid implementation concern (noted in architecture design) but is an infrastructure/platform concern rather than a user-observable behavior. The user does not observe "tilde was expanded" — they observe "the command read/wrote the right file." The existing scenarios already implicitly test this (if tilde expansion fails, the scenarios fail). A dedicated tilde expansion scenario would test implementation details, not user outcomes.

**Action required**: Add as a manual validation checklist note (test on both platforms). No new Gherkin scenario needed.

---

## Coverage Verdict

| Dimension | Status |
|-----------|--------|
| US-1 AC coverage | FULL |
| US-2 AC coverage | FULL |
| US-3 AC coverage | FULL (one low-severity gap handled as checklist item) |
| Error path ratio | 7 of 17 scenarios are error/conflict paths = 41% — MEETS 40% TARGET |
| Walking skeleton present | YES — "Alex runs setup with no existing OTel configuration" is the primary skeleton |
| Property-based scenarios tagged | YES — 2 scenarios tagged @property |
| Business language purity | PASS — no HTTP verbs, status codes, or technical terms in Gherkin |
| GWT structure compliance | PASS — all scenarios have Given/When/Then |

**Overall verdict: APPROVED WITH ONE ADDITION**

One focused scenario (Gap 3) should be added to test-scenarios.md. It does not block handoff — the existing Gherkin is sufficient for the implementer to begin. The additional scenario can be incorporated during the first implementation pass.

---

## Peer Review — critique-dimensions

```yaml
review_id: "accept_rev_2026-03-25-otel-setup"
reviewer: "Quinn (acceptance-designer)"

strengths:
  - "Concrete values throughout — exact key names, exact prefix characters (+/=/!), exact endpoint URL. No vague abstractions."
  - "Error path ratio meets target (41%) — malformed JSON, missing file, conflict, multiple conflicts all covered."
  - "Two @property scenarios correctly tag invariants that signal property-based testing in DELIVER wave."
  - "US-2 partial-match scenario (one correct + one conflicting) is an excellent per-key isolation test."
  - "CLAUDE.md scenarios are user-observable (what Alex sees) not implementation checks (file existence alone)."

issues_identified:
  happy_path_bias:
    - issue: "None — error path ratio is 41%, above 40% threshold."
      severity: "pass"

  gwt_format:
    - issue: "None identified — all scenarios have single When action and observable Then outcomes."
      severity: "pass"

  business_language:
    - issue: "The term 'JSON' appears in malformed-JSON scenario title and body."
      severity: "acceptable — JSON is the domain artifact name here, not a technical implementation term. The user story itself uses 'JSON' in the problem statement. Acceptable domain vocabulary."
    - issue: "The term 'env block' is used throughout."
      severity: "acceptable — 'env block' is the domain term used in architecture design and user stories. Acceptable."

  coverage_gaps:
    - issue: "Mixed +/= output not covered in a single scenario (when some keys already correct, some new)."
      severity: "low — add one focused scenario. Does not block handoff."
      recommendation: "Add scenario: 'Output distinguishes newly added keys from already-correct keys in the same run' with precondition of 2 correct + 3 missing keys."

  walking_skeleton_centricity:
    - issue: "None — primary skeleton ('Alex runs setup with no existing OTel configuration') describes user goal, not technical flow. Then steps describe what Alex observes."
      severity: "pass"

  priority_validation:
    - issue: "None — this is confirmed to be the primary gap blocking Norbert functionality. No simpler alternative was overlooked."
      severity: "pass"

approval_status: "conditionally_approved"
condition: "Add mixed +/= output scenario (Gap 3) to test-scenarios.md. Implementer may proceed with existing Gherkin."
```
