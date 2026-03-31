with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        lower(trim(email))          as email,
        initcap(trim(city))         as city,
        initcap(trim(country))      as country,
        created_at::date            as created_at

    from source
    where customer_id is not null

)

select * from renamed