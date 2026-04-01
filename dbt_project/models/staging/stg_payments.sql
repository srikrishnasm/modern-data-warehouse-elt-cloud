with source as (

    select * from {{ source('raw', 'payments') }}

),

renamed as (
    select
        payment_id,
        order_id,
        payment_method,
        amount,
        payment_date,
        status        as payment_status
    from source
)

select * from renamed