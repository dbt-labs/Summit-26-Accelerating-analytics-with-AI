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

daily_location_metrics as (

    select
        orders.order_date,
        orders.location_id,
        sum(orders.subtotal) as total_revenue,
        count(*) as count_orders,
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
            'daily_location_metrics.order_date',
            'daily_location_metrics.location_id'
        ]) }} as daily_location_performance_key,
        daily_location_metrics.order_date,
        daily_location_metrics.location_id,
        locations.location_name,
        daily_location_metrics.total_revenue,
        daily_location_metrics.count_orders,
        daily_location_metrics.food_revenue,
        daily_location_metrics.drink_revenue

    from daily_location_metrics

    left join locations
        on daily_location_metrics.location_id = locations.location_id

)

select * from final
