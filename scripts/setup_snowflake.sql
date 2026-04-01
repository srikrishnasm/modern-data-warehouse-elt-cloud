-- virtual warehouse (compute)
CREATE WAREHOUSE IF NOT EXISTS ELT_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'ELT cloud project warehouse';

-- database
CREATE DATABASE IF NOT EXISTS ELT_WAREHOUSE;

-- schemas
CREATE SCHEMA IF NOT EXISTS ELT_WAREHOUSE.RAW;
CREATE SCHEMA IF NOT EXISTS ELT_WAREHOUSE.STAGING;
CREATE SCHEMA IF NOT EXISTS ELT_WAREHOUSE.MART;

-- dedicated role
CREATE ROLE IF NOT EXISTS ELT_ROLE;

-- grant role access to warehouse + database
GRANT USAGE ON WAREHOUSE ELT_WH TO ROLE ELT_ROLE;
GRANT ALL ON DATABASE ELT_WAREHOUSE TO ROLE ELT_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE ELT_WAREHOUSE TO ROLE ELT_ROLE;

-- grant role to your user (replace YOUR_USERNAME)
GRANT ROLE ELT_ROLE TO USER YOUR_USERNAME;

-- set context
USE WAREHOUSE ELT_WH;
USE DATABASE ELT_WAREHOUSE;
USE SCHEMA RAW;


USE SCHEMA ELT_WAREHOUSE.RAW;

CREATE OR REPLACE TABLE customers (
    customer_id   INTEGER,
    name          VARCHAR(255),
    email         VARCHAR(255),
    phone         VARCHAR(50),
    country       VARCHAR(100),
    created_at    TIMESTAMP
);

CREATE OR REPLACE TABLE products (
    product_id  INTEGER,
    name        VARCHAR(255),
    category    VARCHAR(100),
    price       FLOAT
);

CREATE OR REPLACE TABLE orders (
    order_id     INTEGER,
    customer_id  INTEGER,
    status       VARCHAR(50),
    order_date   TIMESTAMP,
    updated_at   TIMESTAMP
);

CREATE OR REPLACE TABLE order_items (
    order_item_id  INTEGER,
    order_id       INTEGER,
    product_id     INTEGER,
    quantity       INTEGER,
    unit_price     FLOAT,
    total_price    FLOAT
);

CREATE OR REPLACE TABLE payments (
    payment_id      INTEGER,
    order_id        INTEGER,
    payment_method  VARCHAR(50),
    amount          FLOAT,
    payment_date    TIMESTAMP,
    status          VARCHAR(50)
);


USE SCHEMA ELT_WAREHOUSE.RAW;

CREATE OR REPLACE STAGE s3_raw_stage
  URL = 's3://elt-cloud-raw-srikrishna/raw/'
  CREDENTIALS = (
    AWS_KEY_ID     = 'your_snowflake_s3_access_key',
    AWS_SECRET_KEY = 'your_snowflake_s3_secret_key'
  )
  FILE_FORMAT = (
    TYPE             = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER      = 1
    NULL_IF          = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
  );

-- verify stage can see your S3 files
LIST @s3_raw_stage;


USE SCHEMA ELT_WAREHOUSE.RAW;

COPY INTO customers
  FROM @s3_raw_stage/customers.csv
  ON_ERROR = 'CONTINUE';

COPY INTO products
  FROM @s3_raw_stage/products.csv
  ON_ERROR = 'CONTINUE';

COPY INTO orders
  FROM @s3_raw_stage/orders.csv
  ON_ERROR = 'CONTINUE';

COPY INTO order_items
  FROM @s3_raw_stage/order_items.csv
  ON_ERROR = 'CONTINUE';

COPY INTO payments
  FROM @s3_raw_stage/payments.csv
  ON_ERROR = 'CONTINUE';