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
        order_date,
        location_id,
        subtotal
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

    from order_items

    group by 1

),

orders_with_item_revenue as (

    select
        orders.order_id,
        orders.order_date,
        orders.location_id,
        orders.subtotal,
        coalesce(order_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(order_item_revenue.drink_revenue, 0) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

),

daily_location_aggregates as (

    select
        order_date,
        location_id,

        count(*) as count_orders,
        sum(subtotal) as total_revenue,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from orders_with_item_revenue

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'daily_location_aggregates.order_date',
            'daily_location_aggregates.location_id'
        ]) }} as daily_location_performance_key,
        daily_location_aggregates.order_date,
        daily_location_aggregates.location_id,
        locations.location_name,
        daily_location_aggregates.count_orders,
        daily_location_aggregates.total_revenue,
        daily_location_aggregates.food_revenue,
        daily_location_aggregates.drink_revenue

    from daily_location_aggregates

    left join locations
        on daily_location_aggregates.location_id = locations.location_id

)

select * from final
