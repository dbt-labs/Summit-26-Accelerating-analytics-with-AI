{{
    config(
        materialized='incremental',
        unique_key='daily_location_performance_key',
        incremental_strategy='merge'
    )
}}

with

orders as (

    select * from {{ ref('orders') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

order_item_revenue as (

    select
        order_id,

        sum(
            case
                when is_food_item then product_price
                else 0
            end
        ) as food_revenue,
        sum(
            case
                when is_drink_item then product_price
                else 0
            end
        ) as drink_revenue

    from {{ ref('order_items') }}

    group by 1

),

daily_location_summary as (

    select
        orders.location_id,
        orders.order_date,

        count(distinct orders.order_id) as count_orders,
        sum(orders.order_items_subtotal) as total_revenue,
        sum(coalesce(order_item_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_item_revenue.drink_revenue, 0)) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

    group by 1, 2

),

locations as (

    select * from {{ ref('locations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['daily_location_summary.location_id', 'daily_location_summary.order_date']) }} as daily_location_performance_key,
        daily_location_summary.location_id,
        locations.location_name,
        daily_location_summary.order_date,
        daily_location_summary.count_orders,
        daily_location_summary.total_revenue,
        daily_location_summary.food_revenue,
        daily_location_summary.drink_revenue

    from daily_location_summary

    left join locations
        on daily_location_summary.location_id = locations.location_id

)

select * from final
