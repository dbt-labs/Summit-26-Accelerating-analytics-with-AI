with

orders as (

    select
        order_id,
        order_date,
        location_id,
        subtotal,
        order_total

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

order_dates as (

    select distinct order_date

    from orders

),

location_dates as (

    select
        order_dates.order_date,
        locations.location_id,
        locations.location_name

    from order_dates

    cross join locations

),

order_category_subtotals as (

    select
        order_id,
        sum(case when is_food_item then product_price else 0 end) as food_subtotal,
        sum(case when is_drink_item then product_price else 0 end) as drink_subtotal

    from order_items

    group by 1

),

order_revenue as (

    select
        orders.order_id,
        orders.order_date,
        orders.location_id,
        orders.order_total,
        case
            when orders.subtotal = 0 then 0
            else round(
                orders.order_total
                * order_category_subtotals.food_subtotal
                / orders.subtotal,
                2
            )
        end as food_revenue,
        orders.order_total - food_revenue as drink_revenue

    from orders

    left join order_category_subtotals
        on orders.order_id = order_category_subtotals.order_id

),

daily_performance as (

    select
        order_date,
        location_id,
        sum(order_total) as total_revenue,
        count(order_id) as order_count,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from order_revenue

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'location_dates.order_date',
            'location_dates.location_id'
        ]) }} as location_day_id,
        location_dates.order_date,
        location_dates.location_id,
        location_dates.location_name,
        coalesce(daily_performance.total_revenue, 0) as total_revenue,
        coalesce(daily_performance.order_count, 0) as order_count,
        coalesce(daily_performance.food_revenue, 0) as food_revenue,
        coalesce(daily_performance.drink_revenue, 0) as drink_revenue

    from location_dates

    left join daily_performance
        on location_dates.order_date = daily_performance.order_date
        and location_dates.location_id = daily_performance.location_id

)

select * from final
