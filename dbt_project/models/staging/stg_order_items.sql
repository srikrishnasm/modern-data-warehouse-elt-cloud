with source as (

    select * from {{ source('raw', 'order_items') }}

),

renamed as (

    select
        order_item_id,
        order_id,
        product_id,
        quantity::int               as quantity,
        price::numeric(10,2)        as price

    from source
    where order_item_id  is not null
      and order_id       is not null
      and product_id     is not null
      and quantity       is not null
      and price          is not null

)

select * from renamed