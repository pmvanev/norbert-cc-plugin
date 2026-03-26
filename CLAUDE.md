## Norbert OTel Setup

Norbert requires 5 OTel environment variables in your user-level Claude Code settings to receive metrics and cost tracking data. Without them, Norbert's dashboards stay empty.

Run `/norbert:setup` to merge them into `~/.claude/settings.json` automatically. Norbert must be running on port 3748 before setup has effect.

Restart Claude Code after running `/norbert:setup` for the settings to take effect.
