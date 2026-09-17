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

order_item_revenue as (

    select
        order_id,
        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue

    from order_items

    group by 1

),

daily_performance as (

    select
        orders.order_date,
        orders.location_id,
        count(*) as order_count,
        sum(orders.subtotal) as total_revenue,
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
            'daily_performance.order_date',
            'daily_performance.location_id'
        ]) }} as daily_location_performance_id,
        daily_performance.order_date,
        daily_performance.location_id,
        locations.location_name,
        daily_performance.total_revenue,
        daily_performance.order_count,
        daily_performance.food_revenue,
        daily_performance.drink_revenue

    from daily_performance

    left join locations
        on daily_performance.location_id = locations.location_id

)

select * from final
