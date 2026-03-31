import csv
import os
import random
import boto3

from datetime import datetime, timedelta
from faker import Faker
from dotenv import load_dotenv

load_dotenv("config/.env")

fake = Faker("en_IN")

S3_BUCKET   = os.getenv("S3_BUCKET_NAME", "elt-cloud-raw-srikrishna")
AWS_REGION  = os.getenv("AWS_REGION", "ap-south-1")
NUM_RECORDS = int(os.getenv("NUM_RECORDS", 100))

# ── reference data ────────────────────────────────────────────
CATEGORIES = ["Electronics", "Fashion", "Accessories",
              "Furniture", "Stationery", "Home Appliances"]

PRODUCTS = [
    (1,"Laptop","Electronics",75000), (2,"Phone","Electronics",30000),
    (3,"Headphones","Electronics",3000), (4,"Tablet","Electronics",25000),
    (5,"Smartwatch","Electronics",15000), (6,"T-Shirt","Fashion",800),
    (7,"Jeans","Fashion",2000), (8,"Kurta","Fashion",1200),
    (9,"Saree","Fashion",3500), (10,"Sneakers","Fashion",4000),
    (11,"Wallet","Accessories",1500), (12,"Belt","Accessories",800),
    (13,"Sunglasses","Accessories",2500), (14,"Bag","Accessories",3000),
    (15,"Watch","Accessories",8000), (16,"Sofa","Furniture",35000),
    (17,"Dining Table","Furniture",20000), (18,"Chair","Furniture",8000),
    (19,"Bed Frame","Furniture",25000), (20,"Wardrobe","Furniture",30000),
    (21,"Notebook","Stationery",100), (22,"Pen Set","Stationery",250),
    (23,"Stapler","Stationery",300), (24,"File Folder","Stationery",150),
    (25,"Whiteboard","Stationery",2000), (26,"Washing Machine","Home Appliances",28000),
    (27,"Refrigerator","Home Appliances",45000), (28,"Microwave","Home Appliances",8000),
    (29,"Air Conditioner","Home Appliances",40000), (30,"Vacuum Cleaner","Home Appliances",6000),
]

COUNTRIES  = ["India", "United States", "United Kingdom", "Germany"]
STATUSES   = ["completed", "pending", "cancelled"]
PAYMENTS   = ["UPI", "Credit Card", "Debit Card"]

# ── generators ────────────────────────────────────────────────
def generate_customers(n):
    rows = []
    for i in range(1, n + 1):
        rows.append({
            "customer_id":  i,
            "name":         fake.name(),
            "email":        fake.email(),
            "phone":        fake.phone_number(),
            "country":      random.choice(COUNTRIES),
            "created_at":   fake.date_time_between(
                                start_date="-2y", end_date="now"
                            ).isoformat(),
        })
    return rows

def generate_products():
    return [
        {"product_id": p[0], "name": p[1],
         "category": p[2], "price": p[3]}
        for p in PRODUCTS
    ]

def generate_orders(n, customer_ids):
    rows = []
    for i in range(1, n + 1):
        order_date = fake.date_time_between(
            start_date="-1y", end_date="now"
        )
        rows.append({
            "order_id":    i,
            "customer_id": random.choice(customer_ids),
            "status":      random.choice(STATUSES),
            "order_date":  order_date.isoformat(),
            "updated_at":  (order_date + timedelta(
                                days=random.randint(0, 5)
                            )).isoformat(),
        })
    return rows

def generate_order_items(order_ids):
    rows = []
    item_id = 1
    for oid in order_ids:
        for _ in range(random.randint(1, 4)):
            product = random.choice(PRODUCTS)
            qty     = random.randint(1, 5)
            rows.append({
                "order_item_id": item_id,
                "order_id":      oid,
                "product_id":    product[0],
                "quantity":      qty,
                "unit_price":    product[3],
                "total_price":   product[3] * qty,
            })
            item_id += 1
    return rows

def generate_payments(order_ids):
    rows = []
    for i, oid in enumerate(order_ids, 1):
        rows.append({
            "payment_id":     i,
            "order_id":       oid,
            "payment_method": random.choice(PAYMENTS),
            "amount":         round(random.uniform(500, 100000), 2),
            "payment_date":   fake.date_time_between(
                                  start_date="-1y", end_date="now"
                              ).isoformat(),
            "status":         random.choice(["success", "failed", "pending"]),
        })
    return rows

# ── CSV helpers ───────────────────────────────────────────────
def write_csv(rows, filename):
    if not rows:
        return filename
    os.makedirs("/tmp/elt_raw", exist_ok=True)
    path = f"/tmp/elt_raw/{filename}"
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"  wrote {len(rows)} rows → {path}")
    return path

def upload_to_s3(local_path, filename):
    s3 = boto3.client("s3", region_name=AWS_REGION)
    s3_key = f"raw/{filename}"
    s3.upload_file(local_path, S3_BUCKET, s3_key)
    print(f"  uploaded → s3://{S3_BUCKET}/{s3_key}")

# ── main ──────────────────────────────────────────────────────
def main():
    print(f"\ngenerating {NUM_RECORDS} records ...")

    customers   = generate_customers(NUM_RECORDS)
    products    = generate_products()
    orders      = generate_orders(NUM_RECORDS, [c["customer_id"] for c in customers])
    order_items = generate_order_items([o["order_id"] for o in orders])
    payments    = generate_payments([o["order_id"] for o in orders])

    datasets = {
        "customers.csv":   customers,
        "products.csv":    products,
        "orders.csv":      orders,
        "order_items.csv": order_items,
        "payments.csv":    payments,
    }

    print("\nwriting CSVs + uploading to S3 ...")
    for filename, rows in datasets.items():
        local_path = write_csv(rows, filename)
        upload_to_s3(local_path, filename)

    print("\ndone! all files in s3://{}/raw/".format(S3_BUCKET))

if __name__ == "__main__":
    main()