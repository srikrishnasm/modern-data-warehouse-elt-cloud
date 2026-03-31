with source as (

    select * from {{ source('raw', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_date::date            as order_date,
        lower(trim(status))         as status

    from source
    where order_id     is not null
      and customer_id  is not null

)

select * from renamed