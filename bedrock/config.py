import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# --- Alpaca API Configuration ---
ALPACA_API_KEY = os.getenv("ALPACA_API_KEY")
ALPACA_SECRET_KEY = os.getenv("ALPACA_SECRET_KEY")
ALPACA_API_URL = "https://data.alpaca.markets/v2/stocks"

# --- Azure Blob Storage Configuration ---
AZURE_STORAGE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
RAW_DATA_CONTAINER_NAME = "raw-data"

# --- Data Configuration ---
TICKERS_TO_INGEST = ["SPY", "AAPL", "GOOG", "MSFT"]