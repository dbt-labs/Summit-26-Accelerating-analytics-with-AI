## Naming and keys

- Every model must have a single-column primary key. If the grain has a natural single-column key, name it `<object>_id` (for example, `account_id`). If the grain has no natural single-column key (for example, a grain of one row per location per day), generate a surrogate key. Testing uniqueness across a combination of columns (for example, `dbt_utils.unique_combination_of_columns`) is not a substitute for having an actual primary key column; every model needs one either way.
- Counts should be prefixed with `count_` (for example, `count_orders`), not suffixed (avoid `orders_count`).
- Surrogate/generated keys (for example, keys built with `dbt_utils.generate_surrogate_key`) must be named `<model_name>_key` (for example, `daily_location_performance_key`), not `<model_name>_id`. This distinguishes a generated key from a natural primary key, which is named `<object>_id`.

## Materialization

- Transactional models and models with aggregates derived from transactional data must be materialized as `incremental`, not `table`.

## SQL structure

- Execute aggregations as early as possible, on the smallest data set possible, before joining to another table. Never join a raw, unaggregated table such as `order_items` directly into the same step that performs the final grouping; pre-aggregate it to its own grain in a dedicated CTE first.
- When joining a fact-grain CTE to a dimension/reference table purely to enrich it with a descriptive attribute (for example, joining to `locations` for `location_name`), default to `left join`. Use `inner join` only when rows without a match should be filtered out.
- The final CTE in a model—the one immediately before the closing `select`—must be named `final`. Never name it after the model itself or reuse an earlier CTE's name.

## Governance

- Every mart model must set `config.meta.owner` and `config.group` in its YAML, identifying the team that owns it. See `models/marts/_groups.yml` for the group definition and an existing mart's YAML for the pattern.
