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
        order_date

    from {{ ref('orders') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

order_items as (

    select
        order_id,
        product_price,
        is_food_item,
        is_drink_item

    from {{ ref('order_items') }}

    {% if is_incremental() %}
    where order_date >= (
        select coalesce(dateadd(day, -3, max(order_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

order_revenue as (

    select
        order_id,

        sum(product_price) as total_revenue,
        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue


    from order_items

    group by 1

),

daily_performance as (

    select
        orders.order_date,
        orders.location_id,

        count(orders.order_id) as count_orders,
        sum(coalesce(order_revenue.total_revenue, 0)) as total_revenue,
        sum(coalesce(order_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_revenue.drink_revenue, 0)) as drink_revenue

    from orders

    left join order_revenue on orders.order_id = order_revenue.order_id

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'daily_performance.order_date',
            'daily_performance.location_id'
        ]) }} as daily_location_performance_key,
        daily_performance.order_date,
        daily_performance.location_id,
        locations.location_name,
        daily_performance.count_orders,
        daily_performance.total_revenue,
        daily_performance.food_revenue,
        daily_performance.drink_revenue

    from daily_performance

    left join locations on daily_performance.location_id = locations.location_id

)

select * from final
