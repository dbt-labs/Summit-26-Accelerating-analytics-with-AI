{{
    config(
        materialized='incremental',
        unique_key='location_daily_performance_id',
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

order_items as (

    select * from {{ ref('order_items') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

locations as (

    select * from {{ ref('locations') }}

),

order_item_revenue as (

    select
        order_id,

        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue

    from order_items

    group by 1

),

daily_performance as (

    select
        orders.location_id,
        orders.order_date,

        count(*) as order_count,
        sum(orders.subtotal) as total_revenue,
        sum(coalesce(order_item_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_item_revenue.drink_revenue, 0)) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'daily_performance.location_id',
            'daily_performance.order_date'
        ]) }} as location_daily_performance_id,
        daily_performance.location_id,
        locations.location_name,
        daily_performance.order_date,
        daily_performance.order_count,
        daily_performance.total_revenue,
        daily_performance.food_revenue,
        daily_performance.drink_revenue

    from daily_performance

    left join locations
        on daily_performance.location_id = locations.location_id

)

select * from final
