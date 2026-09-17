with

order_items as (

    select
        order_id,
        product_price,
        is_food_item,
        is_drink_item

    from {{ ref('order_items') }}

),

order_revenue as (

    select
        order_id,
        sum(product_price) as total_revenue,
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

orders as (

    select
        order_id,
        order_date,
        location_id

    from {{ ref('orders') }}

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'orders.order_date',
            'orders.location_id'
        ]) }} as daily_location_performance_id,
        orders.order_date,
        orders.location_id,
        locations.location_name,

        count(*) as order_count,
        sum(coalesce(order_revenue.total_revenue, 0)) as total_revenue,
        sum(coalesce(order_revenue.food_revenue, 0)) as food_revenue,
        sum(coalesce(order_revenue.drink_revenue, 0)) as drink_revenue

    from orders

    inner join locations on orders.location_id = locations.location_id

    left join order_revenue on orders.order_id = order_revenue.order_id

    group by 1, 2, 3, 4

)

select * from final
