with customers as (
    select * from {{ ref('stg_customers') }}
),

final as (
    select
        customer_id,
        customer_name,
        email,
        phone,
        country,
        created_at
    from customers
)

select * from final