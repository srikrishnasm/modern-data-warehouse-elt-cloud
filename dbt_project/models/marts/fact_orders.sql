{{ config(
    materialized='incremental',
    unique_key='order_item_id'
) }}

with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

final as (
    select
        oi.order_item_id,
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,

        oi.product_id,
        pr.product_name,
        pr.category,

        oi.quantity,
        oi.price                            as unit_price,

        p.payment_id,
        p.payment_method,
        p.amount                            as payment_amount,
        p.payment_date,

        (oi.quantity * oi.price)            as total_item_amount

    from order_items oi
    join orders o
        on oi.order_id = o.order_id
    left join payments p
        on o.order_id = p.order_id
    left join products pr
        on oi.product_id = pr.product_id

    {% if is_incremental() %}
    where oi.order_item_id > (
        select coalesce(max(order_item_id), 0) from {{ this }}
    )
    {% endif %}
)

select * from final
