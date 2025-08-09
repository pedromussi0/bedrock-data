import os
import clickhouse_connect
from deltalake import DeltaTable

AZURE_STORAGE_ACCOUNT_NAME = os.environ.get("AZURE_STORAGE_ACCOUNT_NAME")
AZURE_STORAGE_ACCOUNT_KEY = os.environ.get("AZURE_STORAGE_ACCOUNT_KEY")

CLICKHOUSE_HOST = os.environ.get("CLICKHOUSE_HOST", "localhost")
CLICKHOUSE_USER = os.environ.get("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.environ.get("CLICKHOUSE_PASSWORD", "")

# Path to our refined data in Azure Blob Storage
REFINED_DELTA_PATH = "az://refined-data/daily_bars"
CLICKHOUSE_DATABASE = "default"
CLICKHOUSE_TABLE = "daily_bars"

def create_clickhouse_table(client):
    """Creates the target table in ClickHouse if it doesn't exist."""
    print("Ensuring 'daily_bars' table exists in ClickHouse...")
    create_table_ddl = f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.{CLICKHOUSE_TABLE}
    (
        `timestamp` DateTime,
        `ticker` String,
        `open` Float64,
        `high` Float64,
        `low` Float64,
        `close` Float64,
        `volume` Int64
    )
    ENGINE = MergeTree()
    PARTITION BY toYYYYMM(timestamp)
    ORDER BY (ticker, timestamp)
    """
    client.command(create_table_ddl)
    print("Table is ready.")

def main():
    """Main ETL function to move data from Delta Lake to ClickHouse."""
    print("Starting data load from Delta Lake to ClickHouse...")

    # --- UPDATED AUTHENTICATION LOGIC ---
    # 1. Read data from Delta Lake in Azure Blob Storage
    # We now pass the account name and key directly, which is more reliable.
    print(f"Reading from Delta table at: {REFINED_DELTA_PATH}")
    
    if not AZURE_STORAGE_ACCOUNT_NAME or not AZURE_STORAGE_ACCOUNT_KEY:
        print("[ERROR] Please set AZURE_STORAGE_ACCOUNT_NAME and AZURE_STORAGE_ACCOUNT_KEY environment variables.")
        exit(1)
        
    storage_options = {
        "account_name": AZURE_STORAGE_ACCOUNT_NAME,
        "access_key": AZURE_STORAGE_ACCOUNT_KEY
    }
    
    dt = DeltaTable(REFINED_DELTA_PATH, storage_options=storage_options)
    
    # Load the entire table into a Pandas DataFrame
    df = dt.to_pandas()
    print(f"Successfully read {len(df)} rows from Delta Lake.")

    # 2. Connect to ClickHouse and insert the data
    try:
        client = clickhouse_connect.get_client(
            host=CLICKHOUSE_HOST,
            user=CLICKHOUSE_USER,
            password=CLICKHOUSE_PASSWORD
        )
        
        create_clickhouse_table(client)

        print(f"Inserting {len(df)} rows into {CLICKHOUSE_TABLE}...")
        client.insert(f"{CLICKHOUSE_DATABASE}.{CLICKHOUSE_TABLE}", df, column_names='auto')
        print("Data insertion successful.")

    except Exception as e:
        print(f"An error occurred: {e}")
        raise

if __name__ == "__main__":
    main()