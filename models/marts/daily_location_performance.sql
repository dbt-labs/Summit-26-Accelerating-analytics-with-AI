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

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'orders.order_date',
            'orders.location_id'
        ]) }} as daily_location_id,
        orders.order_date,
        orders.location_id,
        locations.location_name,

        count(distinct orders.order_id) as order_count,
        sum(order_items.product_price) as total_revenue,
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

    inner join locations on orders.location_id = locations.location_id

    group by 1, 2, 3, 4

)

select * from final
