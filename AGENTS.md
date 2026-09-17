# Project instructions

## Naming and keys

- Every model must expose a single-column primary key. Use the natural key and name it `<object>_id` when the grain has one. When the grain has no natural single-column key, generate a surrogate key with `dbt_utils.generate_surrogate_key`; testing a combination of columns is not a substitute for an actual primary key column.
- Name generated keys `<model_name>_key`, never `<model_name>_id`, so generated keys are distinguishable from natural identifiers.
- Prefix count columns with `count_`, such as `count_orders`; do not use suffixes such as `orders_count`.

## Materialization

- Materialize transactional models and models containing aggregates derived from transactional data as `incremental`, not `table`.
- Every incremental model must define a reliable `unique_key`. Apply `is_incremental()` filters as early as possible to every import CTE that drives the model grain, and use a lookback window when late-arriving updates are possible. The SQL must remain valid for both incremental and full-refresh runs.

## SQL structure

- Aggregate data as early as possible and at the smallest useful grain before joining it to another table. Never join an unaggregated fact or item-level data set directly into the step that performs the model's final aggregation; pre-aggregate it in a dedicated CTE first.
- Use `left join` when enriching a fact-grain data set with descriptive attributes from a dimension or reference model. Use `inner join` only when unmatched rows should intentionally be removed.
- Name the last CTE before the closing `select` `final`. Do not name it after the model or reuse an earlier CTE name.
- Use `ref()` and `source()` for dbt dependencies; do not hardcode relation names. Select from the closest existing curated model and reuse established business logic instead of rebuilding it from staging or raw sources.
- State and preserve each model's intended grain. Check joins for fanout and do not add, remove, or rename output columns unless the requested change requires it.

## Testing and documentation

- Add `unique` and `not_null` data tests to every model's primary key. Add relationship and business-rule tests where they protect meaningful assumptions introduced by the model.
- Document every model's purpose and grain in its schema YAML. Document calculated columns with their business definition, units, and important edge cases. Use the project's existing `data_tests:` syntax and YAML conventions.

## Building and reviewing model changes

- Before building or changing a model, inspect its SQL, schema YAML, upstream inputs, and downstream dependencies. Preview source data and confirm the columns and values used by the logic rather than inferring them from names.
- Validate SQL model changes with `dbt build --select +<model_name>+` so the changed model, relevant dependencies, and attached tests execute. Use a full refresh when an incremental model's historical logic or schema changes require one, then run a normal incremental build to verify the incremental path.
- Whenever a model is built or changed, complete all three review steps automatically before wrapping up: preview the resulting data as a table in-thread, show the model's lineage, and run `dbt compare --select <model_name>+ --defer` and render the comparison results. If production has no baseline for a new model, state that clearly.
