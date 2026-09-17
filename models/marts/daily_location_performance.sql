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

daily_orders as (

    select
        order_date,
        location_id,

        count(*) as count_orders,
        sum(subtotal) as total_revenue

    from orders

    group by 1, 2

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

daily_item_revenue as (

    select
        orders.order_date,
        orders.location_id,

        sum(order_item_revenue.food_revenue) as food_revenue,
        sum(order_item_revenue.drink_revenue) as drink_revenue

    from order_item_revenue

    inner join orders on order_item_revenue.order_id = orders.order_id

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'daily_orders.order_date',
            'daily_orders.location_id'
        ]) }} as daily_location_performance_key,
        daily_orders.order_date,
        daily_orders.location_id,
        locations.location_name,

        daily_orders.count_orders,
        daily_orders.total_revenue,
        coalesce(daily_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(daily_item_revenue.drink_revenue, 0) as drink_revenue

    from daily_orders

    left join locations on daily_orders.location_id = locations.location_id

    left join daily_item_revenue
        on daily_orders.order_date = daily_item_revenue.order_date
        and daily_orders.location_id = daily_item_revenue.location_id

)

select * from final
