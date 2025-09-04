# Project Bedrock: A Scalable Financial Data Refinery

**Project Bedrock** is an end-to-end data engineering pipeline on **Microsoft Azure**, simulating the core infrastructure of a financial data provider. It ingests, processes, and serves large volumes of market data in a robust and scalable way.  

The workflow spans from raw ingestion to a query-optimized **OLAP serving layer**.

---

## 🏛️ Architecture Overview

**Data Flow:**  
`External API` → `Raw Data Lake (Blob Storage)` → `Data Refinery (Databricks)` → `Refined "Gold" Lake (Delta Lake)` → `OLAP Serving Layer (ClickHouse)`

---

## 🛠️ Tech Stack

- **Cloud:** Azure (Blob Storage, Databricks)  
- **Lakehouse:** Delta Lake (ACID, schema enforcement, versioning)  
- **OLAP:** ClickHouse (columnar DB, MergeTree, fast time-series queries)  
- **Infra:** Docker, Poetry, Azure CLI  
- **Lang:** Python 3.11+  

---

## ⚙️ Pipeline Stages

### 1. Ingestion (Python Service)

- Fetches OHLCV data (Alpaca Markets API).  
- Stores unaltered data in Azure Blob Storage (`raw-data/`), partitioned by date.  
- Establishes an auditable “source of truth”.

### 2. Data Refinery (Azure Databricks)

- Cleans and validates raw data into **refined Delta Lake assets**.  
- Key ops: schema enforcement, corporate action adjustments (splits), schema evolution control.  
- Benefits: ACID transactions, versioning (time travel), reliable analytics.

### 3. OLAP Serving Layer (ClickHouse)

- Refined Delta data is loaded into a **ClickHouse** instance (Dockerized on Azure VM).  
- Schema optimized for time-series lookups (`MergeTree` engine, `ORDER BY (ticker, timestamp)`).  
- Enables low-latency, analytical queries for downstream apps.

---
