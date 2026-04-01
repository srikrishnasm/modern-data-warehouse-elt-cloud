with source as (

    select * from {{ source('raw', 'orders') }}

),

renamed as (
    select
        order_id,
        customer_id,
        status,
        order_date,
        updated_at
    from source
)

select * from renamed