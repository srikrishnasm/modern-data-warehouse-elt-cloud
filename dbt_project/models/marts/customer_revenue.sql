with customers as (

    select * from {{ ref('dim_customers') }}

),

orders as (

    select * from {{ ref('fact_orders') }}

),

aggregated as (

    select
        o.customer_id,
        count(distinct o.order_id)           as total_orders,
        count(distinct o.order_item_id)      as total_items,
        sum(o.total_item_amount)             as total_revenue,
        avg(o.total_item_amount)             as avg_order_item_amount,
        min(o.order_date)                    as first_order_date,
        max(o.order_date)                    as last_order_date

    from orders o
    group by o.customer_id

),

final as (

    select
        c.customer_id,
        c.customer_name,
        c.email,
        c.country,
        c.created_at,

        coalesce(a.total_orders, 0)          as total_orders,
        coalesce(a.total_items, 0)           as total_items,
        coalesce(a.total_revenue, 0)         as total_revenue,
        coalesce(a.avg_order_item_amount, 0) as avg_order_item_amount,
        a.first_order_date,
        a.last_order_date,

        case
            when coalesce(a.total_revenue, 0) >= 100000 then 'Platinum'
            when coalesce(a.total_revenue, 0) >= 50000  then 'Gold'
            when coalesce(a.total_revenue, 0) >= 10000  then 'Silver'
            else 'Bronze'
        end                                  as customer_tier

    from customers c
    left join aggregated a
        on c.customer_id = a.customer_id

)

select * from final