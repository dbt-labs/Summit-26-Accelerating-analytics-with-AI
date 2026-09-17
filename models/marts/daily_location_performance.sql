with

orders as (

    select
        order_id,
        location_id,
        order_date,
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
        location_name,
        opened_date

    from {{ ref('locations') }}

),

order_dates as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="(select min(order_date) from orders)",
        end_date="dateadd(day, 1, (select max(order_date) from orders))"
    ) }}

),

location_dates as (

    select
        cast(order_dates.date_day as date) as order_date,
        locations.location_id,
        locations.location_name

    from order_dates

    cross join locations

    where cast(order_dates.date_day as date) >= locations.opened_date

),

order_item_revenue as (

    select
        order_id,
        sum(case when is_food_item then product_price else 0 end) as food_revenue,
        sum(case when is_drink_item then product_price else 0 end) as drink_revenue

    from order_items

    group by 1

),

orders_with_revenue as (

    select
        orders.order_id,
        orders.location_id,
        orders.order_date,
        orders.subtotal as total_revenue,
        coalesce(order_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(order_item_revenue.drink_revenue, 0) as drink_revenue

    from orders

    left join order_item_revenue
        on orders.order_id = order_item_revenue.order_id

),

daily_orders as (

    select
        order_date,
        location_id,
        count(*) as order_count,
        sum(total_revenue) as total_revenue,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from orders_with_revenue

    group by 1, 2

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'location_dates.order_date',
            'location_dates.location_id'
        ]) }} as daily_location_performance_id,
        location_dates.order_date,
        location_dates.location_id,
        location_dates.location_name,
        coalesce(daily_orders.order_count, 0) as order_count,
        coalesce(daily_orders.total_revenue, 0) as total_revenue,
        coalesce(daily_orders.food_revenue, 0) as food_revenue,
        coalesce(daily_orders.drink_revenue, 0) as drink_revenue

    from location_dates

    left join daily_orders
        on location_dates.order_date = daily_orders.order_date
        and location_dates.location_id = daily_orders.location_id

)

select * from final
