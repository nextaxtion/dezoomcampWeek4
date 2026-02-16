"""
Load NYC Taxi Data for Week 4 dbt Analytics
Downloads data from DataTalksClub repository and loads to BigQuery
"""

import os
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from google.cloud import storage, bigquery
from google.api_core.exceptions import NotFound
import time

# Configuration
PROJECT_ID = "dezoomcamp-486216"
BUCKET_NAME = "dezoomcamp_week4_data"
DATASET_ID = "dezoomcampds"
LOCATION = "us-central1"
CREDENTIALS_FILE = "/home/nextaxtion/deZoomcampWeek2/secrets/gcp-key.json"

# Set credentials
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_FILE

# Initialize clients
storage_client = storage.Client()
bq_client = bigquery.Client()

BASE_URL = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download"
DOWNLOAD_DIR = "/tmp/nyc_taxi_data"
CHUNK_SIZE = 8 * 1024 * 1024

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

def create_bucket_if_not_exists(bucket_name):
    """Create GCS bucket if it doesn't exist"""
    try:
        bucket = storage_client.get_bucket(bucket_name)
        print(f"✓ Bucket {bucket_name} already exists")
    except NotFound:
        print(f"Creating bucket {bucket_name}...")
        bucket = storage_client.create_bucket(bucket_name, location=LOCATION)
        print(f"✓ Bucket {bucket_name} created")
    return bucket

def download_file(taxi_type, year, month):
    """Download a single CSV.GZ file"""
    filename = f"{taxi_type}_tripdata_{year}-{month:02d}.csv.gz"
    url = f"{BASE_URL}/{taxi_type}/{filename}"
    local_path = os.path.join(DOWNLOAD_DIR, filename)
    
    if os.path.exists(local_path):
        print(f"  ⊙ {filename} already downloaded")
        return local_path
    
    try:
        print(f"  ⬇ Downloading {filename}...")
        urllib.request.urlretrieve(url, local_path)
        file_size = os.path.getsize(local_path) / (1024 * 1024)
        print(f"  ✓ Downloaded {filename} ({file_size:.1f} MB)")
        return local_path
    except Exception as e:
        print(f"  ✗ Failed to download {filename}: {e}")
        return None

def upload_to_gcs(bucket, local_path, gcs_path):
    """Upload file to GCS"""
    if not local_path or not os.path.exists(local_path):
        return False
    
    blob = bucket.blob(gcs_path)
    
    # Check if already uploaded
    if blob.exists():
        print(f"  ⊙ {gcs_path} already in GCS")
        return True
    
    try:
        print(f"  ⬆ Uploading to gs://{bucket.name}/{gcs_path}...")
        blob.upload_from_filename(local_path)
        print(f"  ✓ Uploaded {gcs_path}")
        return True
    except Exception as e:
        print(f"  ✗ Upload failed for {gcs_path}: {e}")
        return False

def create_bq_table_from_gcs(taxi_type, table_suffix="_nyc"):
    """Create BigQuery table from GCS CSV.GZ files"""
    table_name = f"{taxi_type}_tripdata{table_suffix}"
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    
    # GCS URI pattern
    gcs_uri = f"gs://{BUCKET_NAME}/{taxi_type}/*.csv.gz"
    
    print(f"\n📊 Creating BigQuery table {table_name}...")
    
    # Configure load job for CSV.GZ
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        autodetect=True,
        skip_leading_rows=1,
    )
    
    # Partition configuration based on taxi type
    if taxi_type == "green":
        job_config.time_partitioning = bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="lpep_pickup_datetime"
        )
    else:  # yellow
        job_config.time_partitioning = bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="tpep_pickup_datetime"
        )
    
    try:
        load_job = bq_client.load_table_from_uri(
            gcs_uri,
            table_id,
            job_config=job_config
        )
        
        load_job.result()  # Wait for job to complete
        
        # Get table info
        table = bq_client.get_table(table_id)
        print(f"✓ Table {table_name} created with {table.num_rows:,} rows")
        return True
    except Exception as e:
        print(f"✗ Failed to create table {table_name}: {e}")
        return False

def process_taxi_data(taxi_type):
    """Download, upload, and load data for one taxi type"""
    print(f"\n{'='*60}")
    print(f"Processing {taxi_type.upper()} taxi data (2019-2020)")
    print(f"{'='*60}")
    
    bucket = create_bucket_if_not_exists(BUCKET_NAME)
    
    # Download files for 2019 and 2020
    print(f"\n📥 Downloading {taxi_type} taxi files...")
    files_to_process = []
    
    for year in [2019, 2020]:
        for month in range(1, 13):
            local_path = download_file(taxi_type, year, month)
            if local_path:
                files_to_process.append((local_path, f"{taxi_type}/{taxi_type}_tripdata_{year}-{month:02d}.csv.gz"))
    
    # Upload to GCS
    print(f"\n☁️  Uploading {taxi_type} files to GCS...")
    for local_path, gcs_path in files_to_process:
        upload_to_gcs(bucket, local_path, gcs_path)
    
    # Create BigQuery table
    create_bq_table_from_gcs(taxi_type, table_suffix="_nyc")
    
    # Cleanup local files
    print(f"\n🧹 Cleaning up local files...")
    for local_path, _ in files_to_process:
        try:
            os.remove(local_path)
        except:
            pass

def main():
    """Main execution"""
    print("="*60)
    print("NYC Taxi Data Loader for Week 4 dbt Analytics")
    print("="*60)
    print(f"Project: {PROJECT_ID}")
    print(f"Dataset: {DATASET_ID}")
    print(f"Bucket: {BUCKET_NAME}")
    print(f"Location: {LOCATION}")
    print("="*60)
    
    start_time = time.time()
    
    # Process green taxi data
    process_taxi_data("green")
    
    # Process yellow taxi data
    process_taxi_data("yellow")
    
    elapsed = time.time() - start_time
    print(f"\n{'='*60}")
    print(f"✅ All data loaded successfully!")
    print(f"⏱️  Total time: {elapsed/60:.1f} minutes")
    print(f"{'='*60}")
    
    print("\n📋 Next steps:")
    print("1. Verify tables in BigQuery:")
    print(f"   - {DATASET_ID}.green_tripdata_nyc")
    print(f"   - {DATASET_ID}.yellow_tripdata_nyc")
    print("2. Update dbt sources.yml to use new tables")
    print("3. Run: dbt build --target prod")

if __name__ == "__main__":
    main()
