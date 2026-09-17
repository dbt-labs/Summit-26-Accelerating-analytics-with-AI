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
        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue

    from order_items

    group by 1

),

orders_enriched as (

    select
        orders.order_id,
        orders.order_date,
        orders.location_id,
        locations.location_name,
        orders.subtotal as total_revenue,
        coalesce(order_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(order_item_revenue.drink_revenue, 0) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

    left join locations
        on orders.location_id = locations.location_id

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_date', 'location_id']) }} as daily_location_id,
        order_date,
        location_id,
        location_name,
        sum(total_revenue) as total_revenue,
        count(order_id) as order_count,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from orders_enriched

    group by 1, 2, 3, 4

)

select * from final
