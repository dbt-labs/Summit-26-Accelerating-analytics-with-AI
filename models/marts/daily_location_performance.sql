with

orders as (

    select * from {{ ref('orders') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

locations as (

    select * from {{ ref('locations') }}

),

daily_orders as (

    select
        order_date,
        location_id,
        count(order_id) as order_count,
        sum(subtotal) as total_revenue

    from orders

    group by 1, 2

),

daily_item_revenue as (

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

    from orders

    inner join order_items on orders.order_id = order_items.order_id

    group by 1, 2

),

final as (

    select
        daily_orders.order_date,
        daily_orders.location_id,
        locations.location_name,
        daily_orders.total_revenue,
        coalesce(daily_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(daily_item_revenue.drink_revenue, 0) as drink_revenue,
        daily_orders.order_count

    from daily_orders

    left join daily_item_revenue
        on daily_orders.order_date = daily_item_revenue.order_date
        and daily_orders.location_id = daily_item_revenue.location_id

    left join locations on daily_orders.location_id = locations.location_id

)

select * from final
