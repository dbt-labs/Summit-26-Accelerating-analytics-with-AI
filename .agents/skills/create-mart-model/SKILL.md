Description "Use when building a new dbt mart model.") - this is what Wizard actually matches against to
   decide whether to use the skill automatically, so it needs to be specific enough to trigger on
   the right kind of request, not just a label.


- Every mart model must set `config.meta.owner` and `config.group` in its yml, identifying
  the team that owns it. See `models/marts/_groups.yml` for the group definition and any
  existing mart's yml for the pattern.
- Transactional models and models with aggregates derived from transactional data should be materialized as `incremental`, not `table`.
