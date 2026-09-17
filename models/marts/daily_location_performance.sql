{{
    config(
        materialized='incremental',
        unique_key='daily_location_performance_key',
        incremental_strategy='merge'
    )
}}

with

locations as (

    select * from {{ ref('locations') }}

),

orders as (

    select * from {{ ref('orders') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

order_items as (

    select * from {{ ref('order_items') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

date_spine as (

    {{
        dbt_utils.date_spine(
            datepart='day',
            start_date="(select min(order_date) from " ~ ref('orders') ~ ")",
            end_date="dateadd(day, 1, (select max(order_date) from " ~ ref('orders') ~ "))"
        )
    }}

),

location_days as (

    select
        date_spine.date_day as order_date,
        locations.location_id,
        locations.location_name

    from date_spine

    cross join locations

    where date_spine.date_day >= locations.opened_date

    {% if is_incremental() %}
        and date_spine.date_day >= (
            select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
            from {{ this }}
        )
    {% endif %}

),

orders_daily as (

    select
        order_date,
        location_id,

        sum(subtotal) as total_revenue,
        count(*) as count_orders

    from orders

    group by 1, 2

),

item_revenue_daily as (

    select
        orders.order_date,
        orders.location_id,

        sum(
            case
                when order_items.is_food_item then order_items.product_price
                else 0
            end
        ) as food_revenue,
        sum(
            case
                when order_items.is_drink_item then order_items.product_price
                else 0
            end
        ) as drink_revenue

    from order_items

    inner join orders on order_items.order_id = orders.order_id

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'location_days.order_date',
            'location_days.location_id'
        ]) }} as daily_location_performance_key,
        location_days.order_date,
        location_days.location_id,
        location_days.location_name,

        coalesce(orders_daily.total_revenue, 0) as total_revenue,
        coalesce(orders_daily.count_orders, 0) as count_orders,
        coalesce(item_revenue_daily.food_revenue, 0) as food_revenue,
        coalesce(item_revenue_daily.drink_revenue, 0) as drink_revenue

    from location_days

    left join orders_daily
        on
            location_days.order_date = orders_daily.order_date
            and location_days.location_id = orders_daily.location_id

    left join item_revenue_daily
        on
            location_days.order_date = item_revenue_daily.order_date
            and location_days.location_id = item_revenue_daily.location_id

)

select * from final
