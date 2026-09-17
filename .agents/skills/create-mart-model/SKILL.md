---
name: create-mart-model
description: Use when building a new dbt mart model, including fact, dimension, aggregate, and reporting models in the marts layer.
---

# Creating a mart model

Apply all project-wide modeling, SQL, testing, documentation, and review standards from `AGENTS.md`. This skill adds the workflow and governance requirements specific to marts.

1. **Define the mart.** State the intended business purpose and grain before writing SQL. Confirm a new mart is warranted and select from the closest existing curated models so established business logic is reused.

2. **Choose the materialization.** Follow the materialization rules in `AGENTS.md`, including the required `unique_key` and incremental filtering pattern when the mart is incremental.

3. **Add mart governance.** In the mart's schema YAML, set `config.group` and `config.meta.owner` to the owning team. Match an existing mart's pattern and use a group defined in `models/marts/_groups.yml`.

4. **Complete the model interface.** Add the model and column documentation and data tests required by `AGENTS.md`, including the single-column primary key and its `unique` and `not_null` tests.

5. **Validate and review.** Re-check the finished mart against `AGENTS.md`, then complete its required build, data preview, lineage visualization, and production comparison before wrapping up.
