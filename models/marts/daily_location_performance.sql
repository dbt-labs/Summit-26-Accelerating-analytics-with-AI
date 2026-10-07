with

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

daily_location_orders as (

    select
        orders.order_date,
        orders.location_id,
        count(*) as order_count,
        sum(orders.subtotal) as total_revenue,
        sum(coalesce(order_item_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_item_revenue.drink_revenue, 0)) as drink_revenue

    from {{ ref('orders') }} as orders

    left join
        order_item_revenue
        on orders.order_id = order_item_revenue.order_id

    group by 1, 2

)

select
    {{ dbt_utils.generate_surrogate_key([
        'daily_location_orders.order_date',
        'daily_location_orders.location_id'
    ]) }} as daily_location_id,
    daily_location_orders.order_date,
    daily_location_orders.location_id,
    locations.location_name,
    daily_location_orders.total_revenue,
    daily_location_orders.order_count,
    daily_location_orders.food_revenue,
    daily_location_orders.drink_revenue

from daily_location_orders

left join
    {{ ref('locations') }} as locations
    on daily_location_orders.location_id = locations.location_id
