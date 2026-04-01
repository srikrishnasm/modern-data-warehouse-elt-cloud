with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (
    select
        customer_id,
        name          as customer_name,
        email,
        phone,
        country,
        created_at
    from source
)

select * from renamed