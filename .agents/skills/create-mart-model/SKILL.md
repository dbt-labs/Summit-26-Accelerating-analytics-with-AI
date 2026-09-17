Use when building a new dbt mart model.

## Model rules

- Every mart model must set `config.meta.owner` and `config.group` in its yml, identifying
  the team that owns it. See `models/marts/_groups.yml` for the group definition and any
  existing mart's yml for the pattern.

## Styling SQL

- Aggregations should be executed as early as possible (on the smallest data set possible) before joining to another table. Never join a raw, un-aggregated table (like `order_items`) directly into the same step that does your final grouping - pre-aggregate it to its own grain in a dedicated CTE first.
- When joining a fact-grain CTE to a dimension/reference table purely to enrich it with a descriptive attribute (for example, joining to `locations` for `location_name`), default to `left join`. Only use `inner join` when you specifically want to filter out rows with no match.
- The final CTE in a model - the one immediately before the closing `select` - should always be named `final`. Never name it after the model itself, and never reuse an earlier CTE's name.
