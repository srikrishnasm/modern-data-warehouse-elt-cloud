with source as (

    select * from {{ source('raw', 'products') }}

),

renamed as (

    select
        product_id,
        initcap(trim(product_name))  as product_name,
        initcap(trim(category))      as category,
        price::numeric(10,2)         as price

    from source
    where product_id  is not null
      and price       is not null
      and price       > 0

)

select * from renamed