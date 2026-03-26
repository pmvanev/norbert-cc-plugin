# ADR-003: Plugin-Local settings.json Disposition

## Status: Accepted

## Context

The norbert-cc-plugin has a `settings.json` at its root with the following content:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/json",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://127.0.0.1:3748"
  }
}
```

Claude Code reads this file for plugin configuration, but it does NOT use the `env` block from plugin-local `settings.json` to activate environment variables in the Claude Code process. The `env` block in `~/.claude/settings.json` (user-level) is the only supported mechanism for setting environment variables that reach Claude Code at session start.

This file is the source of the confusion this feature addresses: developers (and the plugin itself, at one point) assumed this file activated OTel — it does not.

Options:
1. Delete the file — remove the source of confusion
2. Empty the file — keep the file, remove the misleading env block
3. Leave as-is — retain current content, document the trap in README
4. Annotate — add a note inside the JSON (not valid JSON) or alongside it

## Decision

Leave `settings.json` as-is. Add a note to README.md clarifying that this file is NOT the OTel activation mechanism and that `/norbert:setup` writes to `~/.claude/settings.json` instead.

Rationale:
- The file may serve a documentation function — it records the canonical OTel values in a structured form visible in the repository
- Deleting or emptying it provides marginal clarity gain while potentially confusing contributors who expect a settings.json
- The higher-leverage fix is the README note and the `/norbert:setup` command itself — once users run the command, the confusion is resolved regardless of this file's state
- Claude Code may use other keys from plugin settings.json in the future; deleting the file removes that forward compatibility

## Alternatives Considered

### Alternative 1: Delete settings.json
- Why considered: Removes the misleading file entirely
- Why rejected: Marginal benefit vs. risk of breaking any undocumented Claude Code behavior that reads the file. The file may serve future purposes. The `settings.json` filename is conventional for plugin configuration.

### Alternative 2: Empty settings.json to {}
- Why considered: Removes the misleading env block, keeps the file
- Why rejected: Same marginal benefit as deletion. The env values in the file are accurate (they are the canonical values); removing them removes useful documentation.

### Alternative 3: Add a JSON comment (not valid JSON)
- Why considered: Would directly annotate the confusion point
- Why rejected: JSON does not support comments. A trailing comment would make the file invalid JSON, breaking any tooling that reads it.

## Consequences

- Positive: no change required to existing file; no regression risk
- Positive: canonical OTel values remain visible in the repository for reference
- Negative: file continues to look like it might "do something" to casual readers; mitigated by README note
- Mitigation: README.md step 03-01 explicitly states that plugin-local settings.json is not the OTel activation mechanism
