Feature: OTel Setup for Norbert Plugin
  As a developer who has installed the norbert-cc-plugin
  I want to configure OpenTelemetry environment variables with a single command
  So that Norbert receives telemetry data from Claude Code

  Background:
    Given the norbert-cc-plugin is installed in Claude Code
    And ~/.claude/settings.json is the target configuration file
    And the 5 OTel keys are:
      | key                              | value                    |
      | CLAUDE_CODE_ENABLE_TELEMETRY     | 1                        |
      | OTEL_METRICS_EXPORTER            | otlp                     |
      | OTEL_LOGS_EXPORTER               | otlp                     |
      | OTEL_EXPORTER_OTLP_PROTOCOL      | http/json                |
      | OTEL_EXPORTER_OTLP_ENDPOINT      | http://127.0.0.1:3748    |

  # -----------------------------------------------------------------------
  # Step 1: Post-Install Discovery (US-3)
  # -----------------------------------------------------------------------

  Scenario: Alex sees setup instruction in context after installing norbert
    Given Alex has installed the norbert plugin via "/plugin install norbert@pmvanev-plugins"
    And CLAUDE.md exists at the plugin root with setup instructions
    When Alex opens a new Claude Code session
    Then Alex sees a note in context stating OTel setup is required
    And the note includes the exact command "/norbert:setup"
    And the note explains that the command configures ~/.claude/settings.json

  Scenario: CLAUDE.md content is concise and action-oriented
    Given the norbert plugin is enabled
    When Claude Code loads the plugin's CLAUDE.md into context
    Then the CLAUDE.md content is fewer than 10 lines
    And it contains the command "/norbert:setup"
    And it does not duplicate the full README content

  # -----------------------------------------------------------------------
  # Step 2: Happy Path — Fresh Install (US-1)
  # -----------------------------------------------------------------------

  Scenario: Alex runs setup with no existing OTel configuration
    Given Alex's ~/.claude/settings.json contains valid JSON
    And the env block in ~/.claude/settings.json has none of the 5 OTel keys
    When Alex runs "/norbert:setup"
    Then the command reports "No existing OTel keys found"
    And all 5 OTel keys are written into the env block of ~/.claude/settings.json
    And all other keys in ~/.claude/settings.json are unchanged
    And the output lists each key with a "+" prefix indicating it was added
    And the output instructs Alex to restart Claude Code for changes to take effect

  Scenario: Alex runs setup when settings.json has no env block at all
    Given Alex's ~/.claude/settings.json contains valid JSON with no env key
    When Alex runs "/norbert:setup"
    Then the command creates an env block in ~/.claude/settings.json
    And all 5 OTel keys are written into the new env block
    And all pre-existing top-level keys are preserved

  Scenario: Alex runs setup when settings.json has an env block with unrelated keys
    Given Alex's ~/.claude/settings.json has an env block containing "MY_TOKEN=abc123"
    And none of the 5 OTel keys are in the env block
    When Alex runs "/norbert:setup"
    Then all 5 OTel keys are added to the env block
    And MY_TOKEN=abc123 remains in the env block unchanged

  # -----------------------------------------------------------------------
  # Step 3: Idempotent Path — Already Configured (US-1)
  # -----------------------------------------------------------------------

  Scenario: Alex runs setup when all 5 OTel keys are already correct
    Given Alex's ~/.claude/settings.json contains all 5 OTel keys with correct values
    When Alex runs "/norbert:setup"
    Then the command reports "No changes made. OTel is already configured correctly."
    And the output lists all 5 keys with a "=" prefix indicating existing correct values
    And ~/.claude/settings.json is not modified

  Scenario: Alex runs setup multiple times safely
    Given Alex has already run "/norbert:setup" successfully
    When Alex runs "/norbert:setup" again
    Then the command completes without error
    And no duplicate keys are created in ~/.claude/settings.json
    And the output confirms no changes were needed

  # -----------------------------------------------------------------------
  # Step 4: Conflict Path — Existing Different Values (US-2)
  # -----------------------------------------------------------------------

  Scenario: Alex runs setup when one OTel key exists with a different value
    Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
    When Alex runs "/norbert:setup"
    Then the command reports a warning for OTEL_EXPORTER_OTLP_ENDPOINT
    And the warning shows the current value "http://my-otel-collector:4318"
    And the warning shows Norbert's intended value "http://127.0.0.1:3748"
    And no changes are written to ~/.claude/settings.json
    And the output instructs Alex to run "/norbert:setup --force" to overwrite
    And the output instructs Alex to edit ~/.claude/settings.json manually as an alternative

  Scenario: Alex runs setup with multiple conflicting OTel keys
    Given Alex's ~/.claude/settings.json has 3 of the 5 OTel keys with different values
    When Alex runs "/norbert:setup"
    Then the command reports warnings for all 3 conflicting keys
    And each warning shows the current value and Norbert's intended value
    And no changes are written to ~/.claude/settings.json

  Scenario: Alex uses --force to overwrite conflicting keys
    Given Alex's ~/.claude/settings.json has OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
    When Alex runs "/norbert:setup --force"
    Then all 5 OTel keys are written with Norbert's values
    And the output lists each overwritten key with a "!" prefix indicating it was replaced
    And the output confirms Alex's previous values were replaced

  Scenario: Alex has one key with correct value and one with a different value
    Given Alex's ~/.claude/settings.json has CLAUDE_CODE_ENABLE_TELEMETRY set to "1"
    And OTEL_EXPORTER_OTLP_ENDPOINT set to "http://my-otel-collector:4318"
    When Alex runs "/norbert:setup"
    Then only OTEL_EXPORTER_OTLP_ENDPOINT is flagged as a conflict
    And CLAUDE_CODE_ENABLE_TELEMETRY is reported as already correct
    And no changes are written to ~/.claude/settings.json

  # -----------------------------------------------------------------------
  # Step 5: Error Path — Malformed JSON (US-1)
  # -----------------------------------------------------------------------

  Scenario: Alex runs setup with a malformed settings.json
    Given Alex's ~/.claude/settings.json contains invalid JSON (e.g., trailing comma)
    When Alex runs "/norbert:setup"
    Then the command reports "Cannot parse ~/.claude/settings.json as valid JSON"
    And no changes are written to ~/.claude/settings.json
    And the output provides recovery steps including a JSON validator URL
    And the output does not expose a raw stack trace

  Scenario: Alex runs setup when settings.json does not exist
    Given ~/.claude/settings.json does not exist
    When Alex runs "/norbert:setup"
    Then the command reports that settings.json was not found
    And the output shows how to create an empty settings.json
    And no file is created automatically

  # -----------------------------------------------------------------------
  # Properties (ongoing quality)
  # -----------------------------------------------------------------------

  @property
  Scenario: Setup command preserves all non-OTel content in settings.json
    Given ~/.claude/settings.json contains permissions, enabledPlugins, and env with other keys
    When "/norbert:setup" writes the 5 OTel keys
    Then every key outside the 5 OTel target keys is byte-for-byte identical to before the write

  @property
  Scenario: Setup command is safe to run at any time without side effects
    Given Alex runs "/norbert:setup" any number of times in any order
    Then ~/.claude/settings.json always ends in a valid JSON state
    And the OTel keys always have the correct Norbert values after "--force" or a clean run
    And non-OTel settings are never modified
