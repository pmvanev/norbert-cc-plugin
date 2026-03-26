# ADR-001: Command vs Skill for /norbert:setup

## Status: Accepted

## Context

The norbert-cc-plugin needs a user-invocable setup function. Claude Code's plugin system supports two mechanisms for this:

- **Command** (`commands/<name>.md`): A Markdown instruction file. Invoked by the user as `/<plugin>:<name>`. Claude reads the file and executes the instructions. Simple, stateless, no structured metadata required.
- **Skill** (`skills/<name>/SKILL.md`): A Markdown instruction file with richer metadata (description, allowed tools, structured output schema). Designed for multi-step agent tasks and reusable sub-capabilities.

The `/norbert:setup` function is:
- One-shot: reads a file, compares values, optionally writes, reports result
- Idempotent: no persistent state beyond the settings file write
- User-invoked directly: not called by other agents or composed into larger pipelines
- Not multi-turn: does not require the structured output metadata that skills use for inter-agent communication

## Decision

Use `commands/setup.md`. Register as `/norbert:setup` via Claude Code's plugin command resolution (plugin namespace `norbert` + filename `setup`).

## Alternatives Considered

### Alternative 1: skills/setup/SKILL.md (Agent Skill)
- Pros: supports allowed-tools restriction, structured output schema, description metadata
- Cons: overhead of metadata structure adds complexity with no benefit for a one-shot user command; skill mechanism is designed for agent-to-agent invocation, not direct user commands; no multi-turn or composition requirement exists
- Rejected: over-engineered for a single direct-user-invocation use case

### Alternative 2: hooks/SessionStart echo
- Pros: runs automatically, no user action required
- Cons: fires on every session (annoying); stdout-to-user path in hooks is not guaranteed; would run the setup logic every session, not once
- Rejected: wrong trigger frequency and unreliable user-visible output

## Consequences

- Positive: simple implementation, no metadata overhead, directly invocable as `/norbert:setup`
- Positive: `$ARGUMENTS` variable provides `--force` flag support without additional machinery
- Negative: no tool restriction metadata (Claude can use any built-in tool); acceptable since Read, Edit, Bash are all that is needed and over-restriction is not required for a setup command
- Neutral: if the command ever needs to be called by other agents, it can be promoted to a skill at that time
