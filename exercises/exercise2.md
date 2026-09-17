# Exercise 2 - Review the changes

Practical block #2: check if Wizard's output model matches our specific modeling
requirements. If there are any violations, fix them.

*_Note: Your model name might be different and needs to be adjusted in the following exercises._*

1. With `daily_location_performance` open, ask Wizard to preview the resulting data.

<ul>
Show me a preview of daily_location_performance as a table.
</ul>

2. Ask Wizard to visualize the data, right in the thread.

<ul>
Visualize monthly total_revenue by location. Return a bar chart, with months on the y-axis and aggregated revenue on the x-axis. Use a separate bar for each location.
</ul>

3. Ask Wizard to show you where this model sits in the DAG.

<ul>
Show me the lineage for daily_location_performance.
</ul>

4. Ask Wizard to run a `dbt compare` and show you the results.

<ul>
Run a dbt compare on daily_location_performance and show me the results.
</ul>

5. Confirm the data itself looks right at a glance: does revenue look plausible per
   location? Does the food/drink split look plausible? Would you trust this if a store
   manager saw it tomorrow?

6. Now look closer, and compare the model against `team_notes.md` in the `exercises` folder.
   This file contains project-specific modeling and styling rules.
   Wizard's actual output will vary run to run, so not everything below will necessarily be off:

   - **Count columns** - is every count-style column named `count_<noun>` (e.g.
     `count_orders`), or did it come out as `<noun>_count`?
   - **The last CTE** - open the model and look at the CTE immediately before the final
     `select`. Is it named `final`, or something else (including the model's own name)?
   - **Generated keys** - if the model introduces a surrogate/generated key (look for
     `dbt_utils.generate_surrogate_key`), does the column name end in `_key`, or `_id`?
   - **Aggregation order** - find where `order_items` (or any raw, item-level data) is used.
     Is it aggregated to its own grain in a dedicated CTE *before* being joined to anything
     else, or is it joined in raw and grouped directly to the model's final grain in one step?
   - **Join type to `locations`** - is it `left join` or `inner join`?
   - **Materialization** - is this new mart a plain `table`, or `incremental` like `orders`?
     If it did go incremental, check the incremental condition: is it applied to every CTE
     that drives the grain? Is the incremental condition placed on the import CTEs?
   - **yml config** - does it set `config.group` and `config.meta.owner` the same way?
   - **What it's built on** - did Wizard build on top of existing marts (`orders`,
     `order_items`, `locations`), or did it re-join raw sources/staging models and re-derive
     logic (like food/drink classification) that already exists elsewhere?

7. Note down here in the exercise file or on a separate notepad what rule violations you found.

before agent and skill)
Every model has a single-column primary key	✅	The surrogate key is tested not_null and unique.
Counts use the count_ prefix	❌	order_count should be named count_orders.
Generated key uses <model_name>_key	❌	daily_location_performance_id should be daily_location_performance_key.
Mart sets config.meta.owner and config.group	✅	Both are set to analytics_engineering in the YAML.
Transactional aggregates are incremental	❌	The model inherits the marts-level table materialization and has no incremental config.
Aggregate transactional data before joining	✅	order_items is aggregated to order grain in order_revenue before the final joins.
Descriptive dimension enrichment uses a left join	❌	The join to locations is an inner join; the rule calls for a left join unless unmatched orders are intentionally excluded.
Last CTE is named final	✅	The final CTE is correctly named final.

The SQL and YAML both need updating for the two column renames. The incremental conversion also needs a defined incremental strategy and filter—not just materialized: incremental.