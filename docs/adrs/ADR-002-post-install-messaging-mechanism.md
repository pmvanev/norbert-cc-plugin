# ADR-002: Post-Install Messaging Mechanism

## Status: Accepted

## Context

After installing the norbert-cc-plugin, users must run `/norbert:setup` to activate OTel environment variables in `~/.claude/settings.json`. Without this step, hooks fire but no telemetry reaches Norbert's dashboard. The plugin has no install lifecycle hook, so it cannot automatically trigger setup. A mechanism is needed to surface the next-step instruction at the right moment with the right frequency.

Requirements:
- Must surface in context when the plugin is active (not only at install time)
- Must survive across sessions (returning users who missed the first notice)
- Must not fire annoyingly on every prompt or every tool use
- Must not require code or a build step
- Must reference the exact command `/norbert:setup`

## Decision

Use `CLAUDE.md` at the plugin root. Claude Code loads CLAUDE.md from the plugin root directory into session context automatically when the plugin is enabled. Content is minimal: one-sentence description of Norbert, statement that OTel setup is required, the exact command `/norbert:setup`, and a note that Norbert must be running.

This mechanism is confirmed by:
- Official Claude Code plugin-structure documentation
- Observed behavior in installed plugins (nwave-marketplace, pmvanev-plugins/phil)
- Journey analysis in `journey-otel-setup.yaml` (post_install_messaging.decision)

## Alternatives Considered

### Alternative 1: companyAnnouncements in plugin settings.json
- What: Add a `companyAnnouncements` key to the plugin-local `settings.json`
- Why considered: Some plugin settings.json files use this key
- Why rejected: Not a documented Claude Code plugin key. No evidence of support in official plugin-structure docs. Behavior is undefined — it may be silently ignored.

### Alternative 2: SessionStart hook with echo
- What: Add a SessionStart hook that echoes the setup instruction to stdout
- Why considered: Hooks fire automatically, no user action needed
- Why rejected: Fires on every session start — annoying for users who have already run setup. Stdout from hooks is not guaranteed to surface to the user in a readable way. Adds hook complexity for a content-only need.

### Alternative 3: README only
- What: Document setup steps in README.md only
- Why considered: Zero implementation cost
- Why rejected: README is read once at install time and forgotten. Provides no in-context reminder for returning users or team members who inherit the plugin config. No validation that the step was completed.

## Consequences

- Positive: automatic, zero-code, survives across sessions, impossible to miss when plugin is active
- Positive: no hook complexity, no configuration beyond file presence
- Negative: CLAUDE.md content appears in context permanently (even after OTel is configured) — minor context token cost; acceptable given the minimal content constraint (<10 lines)
- Negative: no way to programmatically hide the note after setup completes; user or team can manually remove or edit CLAUDE.md if desired
- Neutral: if Claude Code adds a post-install lifecycle hook in the future, CLAUDE.md can be retired
