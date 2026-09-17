with

orders as (

    select
        order_id,
        location_id,
        order_date,
        subtotal

    from {{ ref('orders') }}

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

    from {{ ref('order_items') }}

    group by 1

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

orders_enriched as (

    select
        orders.order_id,
        orders.location_id,
        locations.location_name,
        orders.order_date,
        orders.subtotal as total_revenue,
        coalesce(order_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(order_item_revenue.drink_revenue, 0) as drink_revenue

    from orders

    left join locations
        on orders.location_id = locations.location_id

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['location_id', 'order_date']) }}
            as daily_location_performance_id,
        location_id,
        location_name,
        order_date,

        count(order_id) as order_count,
        sum(total_revenue) as total_revenue,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from orders_enriched

    group by 1, 2, 3, 4

)

select * from final
