with

order_items as (

    select * from {{ ref('order_items') }}

),

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

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
        orders.subtotal as total_revenue,
        coalesce(order_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(order_item_revenue.drink_revenue, 0) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['orders_enriched.order_date', 'orders_enriched.location_id']) }} as daily_location_sales_id,
        orders_enriched.order_date,
        orders_enriched.location_id,
        locations.location_name,
        sum(orders_enriched.total_revenue) as total_revenue,
        count(orders_enriched.order_id) as order_count,
        sum(orders_enriched.food_revenue) as food_revenue,
        sum(orders_enriched.drink_revenue) as drink_revenue

    from orders_enriched

    inner join locations
        on orders_enriched.location_id = locations.location_id

    group by 1, 2, 3, 4

)

select * from final
