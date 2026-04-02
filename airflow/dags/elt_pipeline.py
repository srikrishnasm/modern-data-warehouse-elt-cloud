from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import snowflake.connector
import os
from dotenv import load_dotenv

load_dotenv("/home/ubuntu/airflow/.env")

# ── config ────────────────────────────────────────────────────
S3_BUCKET          = os.getenv("S3_BUCKET_NAME")
AWS_REGION         = os.getenv("AWS_REGION")
SNOWFLAKE_ACCOUNT  = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_USER     = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")
SNOWFLAKE_WH       = os.getenv("SNOWFLAKE_WAREHOUSE", "ELT_WH")
SNOWFLAKE_DB       = os.getenv("SNOWFLAKE_DATABASE", "ELT_WAREHOUSE")
SNOWFLAKE_ROLE     = os.getenv("SNOWFLAKE_ROLE", "ELT_ROLE")

default_args = {
    "owner":        "elt-cloud",
    "retries":      1,
    "retry_delay":  timedelta(minutes=5),
    "start_date":   datetime(2024, 1, 1),
}

# ── task functions ────────────────────────────────────────────
def run_snowflake_copy():
    conn = snowflake.connector.connect(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        warehouse=SNOWFLAKE_WH,
        database=SNOWFLAKE_DB,
        schema="RAW",
        role=SNOWFLAKE_ROLE,
    )
    cursor = conn.cursor()
    tables = ["customers", "products", "orders", "order_items", "payments"]
    for table in tables:
        cursor.execute(f"TRUNCATE TABLE ELT_WAREHOUSE.RAW.{table}")
        cursor.execute(f"""
            COPY INTO ELT_WAREHOUSE.RAW.{table}
            FROM @ELT_WAREHOUSE.RAW.s3_raw_stage/{table}.csv
            ON_ERROR = 'CONTINUE'
        """)
        print(f"  loaded {table}")
    cursor.close()
    conn.close()
    print("snowflake COPY INTO complete")

def data_quality_check():
    conn = snowflake.connector.connect(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        warehouse=SNOWFLAKE_WH,
        database=SNOWFLAKE_DB,
        role=SNOWFLAKE_ROLE,
    )
    cursor = conn.cursor()
    checks = {
        "RAW.CUSTOMERS":         50,
        "RAW.ORDERS":            50,
        "STAGING.STG_CUSTOMERS": 50,
        "MART.FACT_ORDERS":      50,
        "MART.CUSTOMER_REVENUE": 50,
    }
    failed = []
    for table, min_rows in checks.items():
        cursor.execute(f"SELECT COUNT(*) FROM ELT_WAREHOUSE.{table}")
        count = cursor.fetchone()[0]
        status = "✅" if count >= min_rows else "❌"
        print(f"  {status} {table}: {count} rows")
        if count < min_rows:
            failed.append(table)
    cursor.close()
    conn.close()
    if failed:
        raise ValueError(f"DQ check failed for: {failed}")
    print("all data quality checks passed!")

# ── DAG ───────────────────────────────────────────────────────
with DAG(
    dag_id="elt_pipeline",
    default_args=default_args,
    description="Cloud ELT pipeline — S3 → Snowflake → dbt → DQ check",
    schedule_interval="@daily",
    catchup=False,
    tags=["elt", "cloud", "snowflake", "dbt"],
) as dag:

    generate_data = BashOperator(
        task_id="generate_data",
        bash_command=(
            "source ~/airflow-venv/bin/activate && "
            "export $(cat ~/airflow/.env | grep -v ^# | xargs) && "
            "python3 ~/airflow/scripts/data_generator.py"
        ),
    )

    snowflake_copy = PythonOperator(
        task_id="snowflake_copy",
        python_callable=run_snowflake_copy,
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "source ~/airflow-venv/bin/activate && "
            "export $(cat ~/airflow/.env | grep -v ^# | xargs) && "
            "cd ~/airflow/dbt_project && "
            "dbt run && dbt test"
        ),
    )

    dq_check = PythonOperator(
        task_id="data_quality_check",
        python_callable=data_quality_check,
    )

    generate_data >> snowflake_copy >> dbt_run >> dq_check
