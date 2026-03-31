with source as (

    select * from {{ source('raw', 'payments') }}

),

renamed as (

    select
        payment_id,
        order_id,
        lower(trim(payment_method))  as payment_method,
        amount::numeric(10,2)        as amount,
        payment_date::date           as payment_date

    from source
    where payment_id   is not null
      and order_id     is not null
      and amount       is not null
      and amount       > 0

)

select * from renamed