/*
    STAGING MODEL: stg_green_tripdata
    
    Purpose: Clean and standardize raw green taxi data
    
    What this model does:
    1. Reads from the raw BigQuery table
    2. Renames columns to lowercase with underscores (naming convention)
    3. Casts data types explicitly for consistency
    4. Filters out invalid records (nulls, negatives)
    5. Adds a service_type column to identify the taxi type
*/

-- Step 1: Reference the raw data using source()
-- This tells dbt where to find the data
WITH raw_green AS (
    SELECT *
    FROM {{ source('raw', 'green_tripdata_nyc') }}
)

-- Step 2: Select and transform the columns we need
SELECT
    -- Identifiers (cast to proper types)
    CAST(vendorid AS INTEGER) AS vendor_id,
    CAST(ratecodeid AS INTEGER) AS ratecode_id,
    CAST(pulocationid AS INTEGER) AS pickup_location_id,
    CAST(dolocationid AS INTEGER) AS dropoff_location_id,
    
    -- Timestamps
    lpep_pickup_datetime AS pickup_datetime,
    lpep_dropoff_datetime AS dropoff_datetime,
    
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
    CAST(ehail_fee AS NUMERIC) AS ehail_fee,  -- Cast to NUMERIC for consistency with yellow
    improvement_surcharge,
    total_amount,
    CAST(NULL AS NUMERIC) AS congestion_surcharge,  -- Green doesn't have this
    
    -- Add a column to identify this as green taxi data
    'Green' AS service_type

FROM raw_green

-- Step 3: Filter out bad data
WHERE 
    -- Remove records with null IDs (can't join without them)
    vendorid IS NOT NULL
    AND pulocationid IS NOT NULL
    AND dolocationid IS NOT NULL
    -- Remove invalid trips using variables from dbt_project.yml
    AND trip_distance > {{ var('min_trip_distance') }}
    AND total_amount > {{ var('min_trip_amount') }}
    -- Filter for 2019-2020 data only
    AND EXTRACT(YEAR FROM lpep_pickup_datetime) BETWEEN 2019 AND 2020
    -- Filter for 2019-2020 data only
    AND EXTRACT(YEAR FROM lpep_pickup_datetime) BETWEEN 2019 AND 2020
