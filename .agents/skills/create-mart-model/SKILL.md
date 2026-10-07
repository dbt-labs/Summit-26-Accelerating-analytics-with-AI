## Frontmatter
Use when building a new dbt mart model for this project.

- Every mart model must set `config.meta.owner` and `config.group` in its yml, identifying
  the team that owns it. See `models/marts/_groups.yml` for the group definition and any
  existing mart's yml for the pattern.
- Transactional models and models with aggregates derived from transactional data should be materialized as `incremental`, not `table`.
- preview the resulting data in-thread, show the model's lineage, and run a `dbt compare` to show what changed

