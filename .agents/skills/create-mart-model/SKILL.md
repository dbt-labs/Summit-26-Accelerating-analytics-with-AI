---
name: create-mart-model
description: Use when building a new dbt mart model in this project.
---

# Create a mart model

Apply all general project standards in the root `AGENTS.md`, then apply these mart-specific rules.

## Governance

- Every mart model must set `config.meta.owner` and `config.group` in its schema YAML to identify the owning team.
- Read `models/marts/_groups.yml` for valid group definitions and inspect an existing mart's YAML for the project's ownership pattern before adding the configuration.
- Keep `config.meta.owner` and `config.group` consistent with the corresponding team and neighboring mart models.

Before finishing, re-check the mart against this skill and complete the automatic model-review workflow required by `AGENTS.md`.
