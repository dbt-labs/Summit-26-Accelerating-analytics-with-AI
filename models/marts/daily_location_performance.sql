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

order_daily as (

    select
        order_date,
        location_id,
        count(*) as order_count,
        sum(subtotal) as total_revenue

    from orders

    group by 1, 2

),

item_daily as (

    select
        order_items.order_date,
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
            'order_daily.order_date',
            'order_daily.location_id'
        ]) }} as daily_location_performance_id,
        order_daily.order_date,
        order_daily.location_id,
        locations.location_name,
        order_daily.total_revenue,
        order_daily.order_count,
        coalesce(item_daily.food_revenue, 0) as food_revenue,
        coalesce(item_daily.drink_revenue, 0) as drink_revenue

    from order_daily

    left join item_daily
        on order_daily.order_date = item_daily.order_date
        and order_daily.location_id = item_daily.location_id

    left join locations on order_daily.location_id = locations.location_id

)

select * from final
