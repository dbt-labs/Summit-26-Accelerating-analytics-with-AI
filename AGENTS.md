# Project standards

These rules apply whenever building or changing a dbt model in this project.

## Grain, naming, and keys

- State the model grain explicitly before writing SQL and preserve that grain throughout the model.
- Every model must have a single-column primary key. If the grain has a natural single-column key, name it `<object>_id` (for example, `account_id`). If the grain has no natural single-column key (for example, one row per location per day), generate a surrogate key. Testing uniqueness across a combination of columns, such as `dbt_utils.unique_combination_of_columns`, is not a substitute for an actual primary-key column.
- Name surrogate or generated keys `<model_name>_key` (for example, `daily_location_performance_key`), never `<model_name>_id`. Reserve `<object>_id` for natural keys.
- Prefix count columns with `count_` (for example, `count_orders`); do not use suffixes such as `orders_count`.

## SQL structure

- Use `ref()` and `source()` for dbt relations; do not hardcode database relation names in model SQL.
- Aggregate as early as possible, on the smallest practical dataset, before joining to another table. Never join raw, unaggregated rows such as `order_items` directly into the same step that performs the final grouping. Pre-aggregate them to their required grain in a dedicated CTE first.
- When enriching a fact-grain CTE with descriptive attributes from a dimension or reference table, default to a `left join`. Use an `inner join` only when unmatched fact rows should intentionally be removed.
- Name the final CTE immediately before the closing `select` `final`. Do not name it after the model or reuse an earlier CTE name.
- Preserve the existing model interface unless the requested change explicitly alters it: do not remove, rename, retype, or invent columns as a side effect.

## Materialization

- Materialize transactional models and models with aggregates derived from transactional data as `incremental`, not `table`.
- For incremental models, define a valid `unique_key` and apply the incremental boundary to every input CTE that drives the model grain.

## Documentation and tests

- Document the model's purpose and grain in its schema YAML, and document every output column.
- Add `not_null` and `unique` data tests to the model's primary-key column.
- Read the relevant upstream models and their YAML before implementing logic so existing definitions are reused instead of re-derived.

## Automatic model review

- Whenever building or changing a model, complete the review workflow automatically without waiting for a separate request:
  1. Build and validate the affected dependency slice.
  2. Preview the resulting development data in-thread with `dbt show`.
  3. Show the model's lineage in-thread.
  4. Run `dbt compare` for the changed model and its downstream models against production, then render the comparison results in-thread. If a new model has no production baseline, state that clearly instead of skipping the comparison silently.
