/*
    STAGING MODEL: stg_yellow_tripdata
    
    Purpose: Clean and standardize raw yellow taxi data
    
    What this model does:
    1. Reads from the raw BigQuery table
    2. Renames columns to match green taxi model (for later UNION)
    3. Casts data types explicitly for consistency
    4. Filters out invalid records (nulls, negatives)
    5. Adds a service_type column to identify the taxi type
    
    Note: Yellow taxi uses 'tpep' prefix (not 'lpep' like green)
          Yellow has congestion_surcharge (green doesn't)
          Yellow does NOT have ehail_fee (green does)
*/

-- Step 1: Reference the raw data using source()
WITH raw_yellow AS (
    SELECT *
    FROM {{ source('raw', 'yellow_tripdata_nyc') }}
)

-- Step 2: Select and transform the columns we need
SELECT
    -- Identifiers (cast to proper types)
    CAST(vendorid AS INTEGER) AS vendor_id,
    CAST(ratecodeid AS INTEGER) AS ratecode_id,
    CAST(pulocationid AS INTEGER) AS pickup_location_id,
    CAST(dolocationid AS INTEGER) AS dropoff_location_id,
    
    -- Timestamps (notice: tpep not lpep)
    tpep_pickup_datetime AS pickup_datetime,
    tpep_dropoff_datetime AS dropoff_datetime,
    
    -- Trip info
    store_and_fwd_flag,
    CAST(passenger_count AS INTEGER) AS passenger_count,
    trip_distance,
    
    -- Payment info
    CAST(payment_type AS INTEGER) AS payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    CAST(NULL AS NUMERIC) AS ehail_fee,  -- Yellow doesn't have this
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    
    -- Add a column to identify this as yellow taxi data
    'Yellow' AS service_type

FROM raw_yellow

-- Step 3: Filter out bad data (same logic as green)
WHERE 
    vendorid IS NOT NULL
    AND pulocationid IS NOT NULL
    AND dolocationid IS NOT NULL
    AND trip_distance > 0
    AND total_amount > 0
    -- Filter for 2019-2020 data only
    AND EXTRACT(YEAR FROM tpep_pickup_datetime) BETWEEN 2019 AND 2020
