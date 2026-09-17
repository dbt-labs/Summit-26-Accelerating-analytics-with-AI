{{
    config(
        materialized='incremental',
        unique_key='daily_location_performance_key',
        incremental_strategy='merge'
    )
}}

with

orders as (

    select
        order_id,
        location_id,
        order_date,
        subtotal

    from {{ ref('stg_orders') }}

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
        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue

    from {{ ref('order_items') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

    group by 1

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['orders.order_date', 'orders.location_id']) }} as daily_location_performance_key,
        orders.order_date,
        orders.location_id,
        locations.location_name,
        sum(orders.subtotal) as total_revenue,
        count(orders.order_id) as count_orders,
        sum(coalesce(order_item_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_item_revenue.drink_revenue, 0)) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

    left join locations
        on orders.location_id = locations.location_id

    group by 1, 2, 3, 4

)

select * from final
