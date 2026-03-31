with customers as (

    select * from {{ ref('stg_customers') }}

),

final as (

    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name  as full_name,
        email,
        city,
        country,
        created_at

    from customers

)

select * from final