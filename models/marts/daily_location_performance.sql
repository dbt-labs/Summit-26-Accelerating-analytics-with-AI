with

orders as (

    select
        order_id,
        location_id,
        order_date,
        subtotal

    from {{ ref('orders') }}

),

order_items as (

    select
        order_id,
        product_price,
        is_food_item,
        is_drink_item

    from {{ ref('order_items') }}

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

daily_orders as (

    select
        location_id,
        order_date,
        sum(subtotal) as total_revenue,
        count(*) as order_count

    from orders

    group by 1, 2

),

daily_item_revenue as (

    select
        orders.location_id,
        orders.order_date,
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
        daily_orders.order_date,
        daily_orders.location_id,
        locations.location_name,
        daily_orders.total_revenue,
        daily_orders.order_count,
        coalesce(daily_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(daily_item_revenue.drink_revenue, 0) as drink_revenue

    from daily_orders

    inner join locations on daily_orders.location_id = locations.location_id

    left join daily_item_revenue
        on daily_orders.location_id = daily_item_revenue.location_id
        and daily_orders.order_date = daily_item_revenue.order_date

)

select * from final
