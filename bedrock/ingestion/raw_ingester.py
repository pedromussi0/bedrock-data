import requests
import pandas as pd
from datetime import date, timedelta
from io import StringIO

from azure.storage.blob import BlobServiceClient

from bedrock import config

def fetch_daily_data_from_alpaca(ticker: str, day: date) -> pd.DataFrame | None:
    """
    Fetches daily OHLCV bar data for a given ticker from Alpaca.
    Alpaca's free tier provides IEX data.
    """
    print(f"Fetching data for {ticker} on {day.isoformat()}...")
    
    # Alpaca's API requires the date range to be specified.
    # For a single day, start and end are the same.
    start_date = day.isoformat()
    end_date = day.isoformat()

    api_url = f"{config.ALPACA_API_URL}/bars"
    
    headers = {
        "APCA-API-KEY-ID": config.ALPACA_API_KEY,
        "APCA-API-SECRET-KEY": config.ALPACA_SECRET_KEY
    }
    
    params = {
        "symbols": ticker,
        "timeframe": "1Day",
        "start": start_date,
        "end": end_date,
        "adjustment": "raw" # Important: we want raw data to do our own adjustments later
    }

    try:
        response = requests.get(api_url, headers=headers, params=params)
        response.raise_for_status()  # Raises an HTTPError for bad responses (4xx or 5xx)
        
        data = response.json()
        
        if not data["bars"] or ticker not in data["bars"]:
            print(f"No data found for {ticker} on {day.isoformat()}.")
            return None
            
        # Convert the bar data into a pandas DataFrame
        df = pd.DataFrame(data["bars"][ticker])
        df['ticker'] = ticker # Add ticker symbol as a column
        print(f"Successfully fetched {len(df)} rows for {ticker}.")
        return df

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data for {ticker}: {e}")
        return None

def upload_df_to_azure_blob(df: pd.DataFrame, ticker: str, day: date):
    """
    Uploads a pandas DataFrame to Azure Blob Storage as a CSV file,
    partitioned by date and ticker.
    """
    # Define a structured path. This is CRITICAL for a data lake.
    # Format: YYYY/MM/DD/TICKER.csv
    blob_path = f"{day.strftime('%Y/%m/%d')}/{ticker}.csv"
    
    print(f"Uploading to Azure Blob Storage at path: {blob_path}")

    try:
        # Initialize the Blob Service Client from the connection string in our config
        blob_service_client = BlobServiceClient.from_connection_string(config.AZURE_STORAGE_CONNECTION_STRING)
        
        # Get a client to interact with the specific container and blob
        blob_client = blob_service_client.get_blob_client(
            container=config.RAW_DATA_CONTAINER_NAME, 
            blob=blob_path
        )
        
        # Convert DataFrame to a CSV string in memory
        output = StringIO()
        df.to_csv(output, index=False)
        
        # Upload the data. The `data` argument needs to be bytes, so we encode the string.
        blob_client.upload_blob(output.getvalue().encode('utf-8'), overwrite=True)
        
        print(f"Successfully uploaded {blob_path}.")

    except Exception as e:
        print(f"Error uploading to Azure Blob Storage: {e}")

def main():
    """
    Main execution function.
    Fetches yesterday's data for a list of tickers and stores it in Azure.
    """
    print("Starting daily raw data ingestion job...")
    
    # We will ingest data for yesterday as it's the most recent complete day.
    ingestion_date = date.today() - timedelta(days=1)
    
    for ticker in config.TICKERS_TO_INGEST:
        daily_df = fetch_daily_data_from_alpaca(ticker, ingestion_date)
        
        if daily_df is not None and not daily_df.empty:
            upload_df_to_azure_blob(daily_df, ticker, ingestion_date)
            
    print("Ingestion job finished.")

if __name__ == "__main__":
    main()