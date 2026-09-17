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

orders_daily as (

    select
        order_date,
        location_id,

        count(*) as order_count,
        sum(subtotal) as total_revenue

    from orders

    group by 1, 2

),

order_items_daily as (

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
            'orders_daily.order_date',
            'orders_daily.location_id'
        ]) }} as daily_location_performance_id,
        orders_daily.order_date,
        orders_daily.location_id,
        locations.location_name,

        orders_daily.order_count,
        orders_daily.total_revenue,
        coalesce(order_items_daily.food_revenue, 0) as food_revenue,
        coalesce(order_items_daily.drink_revenue, 0) as drink_revenue

    from orders_daily

    inner join locations on orders_daily.location_id = locations.location_id

    left join order_items_daily
        on orders_daily.order_date = order_items_daily.order_date
        and orders_daily.location_id = order_items_daily.location_id

)

select * from final
