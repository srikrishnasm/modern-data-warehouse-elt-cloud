# Modern Data Warehouse — ELT Pipeline

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat&logo=python&logoColor=white)](https://python.org)
[![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-2.8.4-017CEE?style=flat&logo=apacheairflow&logoColor=white)](https://airflow.apache.org)
[![dbt](https://img.shields.io/badge/dbt-1.10.0-FF694B?style=flat&logo=dbt&logoColor=white)](https://getdbt.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?style=flat&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Apache Superset](https://img.shields.io/badge/Apache%20Superset-3.0.0-20A6C9?style=flat&logo=apachesuperset&logoColor=white)](https://superset.apache.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker&logoColor=white)](https://docker.com)

A fully containerized, end-to-end ELT data pipeline that generates synthetic e-commerce data, ingests it into PostgreSQL, transforms it with dbt, and visualizes it in Apache Superset — all orchestrated by Apache Airflow.

---

## Pipeline overview

```
CSV generation (Faker)
       ↓
Airflow DAG orchestration
       ↓
Raw ingestion → PostgreSQL (raw schema)
       ↓
dbt transformations
   ├── staging schema  (cleaned, typed views)
   └── mart schema     (dim/fact/revenue tables)
       ↓
Apache Superset dashboard
```

---



## Architecture diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker network                       │
│                                                             │
│  ┌──────────────┐    ┌───────────────┐    ┌──────────────┐  │
│  │   Airflow    │    │  PostgreSQL   │    │   Superset   │  │
│  │  :8081       │───▶│  :5432        │◀───│  :8088       │  │
│  │              │    │               │    │              │  │
│  │  DAG tasks:  │    │  elt_warehouse│    │  Dashboards  │  │
│  │  1. generate │    │  ├── raw      │    │  Charts      │  │
│  │  2. ingest   │    │  ├── staging  │    │  Datasets    │  │
│  │  3. dbt run  │    │  └── mart     │    │              │  │
│  │  4. dbt test │    │               │    │              │  │
│  │  5. dq check │    │  airflow_db   │    │  superset_db │  │
│  └──────────────┘    └───────────────┘    └──────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech stack

| Layer | Tool | Purpose |
|---|---|---|
| Orchestration | Apache Airflow 2.8.4 | DAG scheduling and task management |
| Data generation | Python + Faker | Synthetic e-commerce data |
| Ingestion | psycopg2 + Python | CSV → PostgreSQL raw schema |
| Storage | PostgreSQL 15 | Raw, staging, and mart schemas |
| Transformation | dbt 1.10.0 | Staging views + mart tables |
| Visualization | Apache Superset 3.0.0 | Interactive dashboards |
| Containerization | Docker + Compose | Full stack in one command |

---

## Project structure

```
modern-data-warehouse-elt/
│
├── docker/
│   ├── docker-compose.yml          # all services
│   ├── .env                        # credentials (gitignored)
│   ├── .env.example                # safe template
│   │
│   ├── airflow/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── dags/
│   │       └── elt_pipeline.py     # main DAG
│   │
│   ├── ingestion/
│   │   ├── Dockerfile
│   │   └── scripts/
│   │       ├── data_generator.py   # Faker data generation
│   │       └── load_data.py        # CSV → Postgres ingestion
│   │
│   ├── postgres/
│   │   └── init.sql                # schemas + raw tables
│   │
│   ├── dbt/
│   │   └── profiles.yml            # dbt connection config
│   │
│   └── superset/
│       ├── Dockerfile
│       └── superset_config.py
│
├── dbt_project/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml
│   │   │   ├── staging.yml
│   │   │   ├── stg_customers.sql
│   │   │   ├── stg_orders.sql
│   │   │   ├── stg_order_items.sql
│   │   │   ├── stg_payments.sql
│   │   │   └── stg_products.sql
│   │   └── marts/
│   │       ├── marts.yml
│   │       ├── dim_customers.sql
│   │       ├── dim_products.sql
│   │       ├── fact_orders.sql
│   │       └── customer_revenue.sql
│   └── macros/
│       ├── generate_schema_name.sql
│       └── tests/
│           ├── email_format.sql
│           ├── no_future_date.sql
│           └── positive_value.sql
│
├── data/
│   └── raw/                        # generated CSV files
│
├── .gitignore
└── README.md
```

---

## dbt lineage

```
raw.customers ──────────────────► stg_customers ──► dim_customers ──► customer_revenue
raw.orders ─────────────────────► stg_orders ─────┐
raw.order_items ────────────────► stg_order_items ─┼─► fact_orders ──► customer_revenue
raw.payments ───────────────────► stg_payments ────┘
raw.products ───────────────────► stg_products ───► dim_products ───► fact_orders
```

### dbt models

| Model | Schema | Type | Description |
|---|---|---|---|
| `stg_customers` | staging | view | Cleaned customer records |
| `stg_orders` | staging | view | Cleaned order records |
| `stg_order_items` | staging | view | Cleaned order line items |
| `stg_payments` | staging | view | Cleaned payment records |
| `stg_products` | staging | view | Cleaned product catalog |
| `dim_customers` | mart | table | Customer dimension |
| `dim_products` | mart | table | Product dimension |
| `fact_orders` | mart | incremental | Order fact table |
| `customer_revenue` | mart | table | Revenue aggregation per customer |

---

## Airflow DAG

```
generate_data → run_ingestion → wait_for_postgres → run_dbt → data_quality_check
```

| Task | Type | Description |
|---|---|---|
| `generate_data` | BashOperator | Generate synthetic CSV data using Faker |
| `run_ingestion` | BashOperator | Load CSVs into raw PostgreSQL schema |
| `wait_for_postgres` | PythonOperator | Verify DB connection before dbt runs |
| `run_dbt` | BashOperator | Run dbt debug, deps, run, test |
| `data_quality_check` | PythonOperator | Validate row counts across all layers |

---

## Dashboard screenshots

> Screenshots will be added after Superset dashboard is finalized.

---

## Quick start

### Prerequisites

- Docker and Docker Compose installed
- Git

### Setup

```bash
# 1. clone the repo
git clone git@github.com:srikrishnasm/modern-data-warehouse-elt.git
cd modern-data-warehouse-elt

# 2. create your .env file
cp docker/.env.example docker/.env

# 3. build and start all containers
docker-compose -f docker/docker-compose.yml up --build -d

# 4. wait for airflow-init to complete
docker logs airflow_init -f

# 5. add postgres connection in airflow UI
# go to http://localhost:8081 → Admin → Connections → +
# Connection Id: elt_postgres
# Connection Type: Postgres
# Host: postgres | Schema: elt_warehouse | Login: postgres | Password: postgres | Port: 5432
```

### Run the pipeline

```bash
# trigger DAG manually (default: 10 records)
# go to http://localhost:8081 → elt_pipeline → trigger
# or via CLI:
docker exec -it airflow_webserver airflow dags trigger elt_pipeline
```

### Access services

| Service | URL | Credentials |
|---|---|---|
| Airflow | http://localhost:8081 | admin / admin |
| Superset | http://localhost:8088 | admin / admin |
| PostgreSQL | localhost:5433 | postgres / postgres |

### Connect Superset to your warehouse

1. Go to http://localhost:8088 → Settings → Database Connections → + Database
2. Select PostgreSQL
3. Fill in: Host `postgres`, Port `5432`, Database `elt_warehouse`, Username `postgres`, Password `postgres`
4. Test connection → Connect
5. Go to Datasets → add mart tables → build charts

---

## Data model

### Generated data (Faker)

- 30 products across 6 categories (Electronics, Fashion, Accessories, Furniture, Stationery, Home Appliances)
- Customers from 4 countries (India, United States, United Kingdom, Germany)
- Orders with status: completed / pending / cancelled
- Payments via UPI, Credit Card, Debit Card

### Customer tier segmentation (customer_revenue)

| Tier     | Total revenue |
|----------|---------------|
| Platinum | ≥ ₹1,00,000 |
| Gold     | ≥ ₹50,000   |
| Silver   | ≥ ₹10,000   |
| Bronze   | < ₹10,000   |

---

## Custom dbt tests

| Test | Description |
|------|-------------|
| `email_format` | Validates email contains `@` and `.` |
| `no_future_date` | Ensures dates are not in the future |
| `positive_value` | Ensures numeric values are greater than zero |

---

## Stop and reset

```bash
# stop all containers (keep data)
docker-compose -f docker/docker-compose.yml stop

# stop and wipe everything (fresh start)
docker-compose -f docker/docker-compose.yml down -v
```

---

## Author

[@srikrishnasm](https://github.com/srikrishnasm)