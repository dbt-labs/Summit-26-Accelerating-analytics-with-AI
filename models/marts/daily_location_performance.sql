with

orders as (

    select
        order_id,
        order_date,
        location_id,
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

order_summary as (

    select
        order_date,
        location_id,
        count(*) as order_count,
        sum(subtotal) as total_revenue

    from orders

    group by 1, 2

),

item_summary as (

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
        {{ dbt_utils.generate_surrogate_key([
            'order_summary.order_date',
            'order_summary.location_id'
        ]) }} as daily_location_performance_id,
        order_summary.order_date,
        order_summary.location_id,
        locations.location_name,
        order_summary.total_revenue,
        order_summary.order_count,
        coalesce(item_summary.food_revenue, 0) as food_revenue,
        coalesce(item_summary.drink_revenue, 0) as drink_revenue

    from order_summary

    inner join locations on order_summary.location_id = locations.location_id

    left join item_summary
        on order_summary.order_date = item_summary.order_date
        and order_summary.location_id = item_summary.location_id

)

select * from final
