/*
    MART MODEL: fact_trips
    
    Purpose: Business-ready fact table with trip metrics and calculations
    
    What this model does:
    1. Takes the unioned trip data
    2. Adds calculated fields (trip duration, revenue per mile, etc.)
    3. Enriches with business logic
    4. Creates the final table for dashboards and analysis
    
    This is what analysts will query!
*/

WITH unioned_trips AS (
    SELECT * FROM {{ ref('int_trips_unioned') }}
)

SELECT
    -- Trip identifiers
    vendor_id,
    service_type,  -- 'Green' or 'Yellow'
    
    -- Location
    pickup_location_id,
    dropoff_location_id,
    
    -- Time
    pickup_datetime,
    dropoff_datetime,
    DATETIME_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_duration_minutes,
    EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
    EXTRACT(DAYOFWEEK FROM pickup_datetime) AS pickup_day_of_week,
    EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,
    
    -- Trip details
    passenger_count,
    trip_distance,
    ratecode_id,
    store_and_fwd_flag,
    payment_type,
    
    -- Financial amounts
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    congestion_surcharge,
    total_amount,
    
    -- Calculated metrics
    CASE 
        WHEN trip_distance > 0 THEN total_amount / trip_distance 
        ELSE NULL 
    END AS revenue_per_mile,
    
    CASE 
        WHEN DATETIME_DIFF(dropoff_datetime, pickup_datetime, MINUTE) > 0 
        THEN trip_distance / (DATETIME_DIFF(dropoff_datetime, pickup_datetime, MINUTE) / 60.0)
        ELSE NULL 
    END AS avg_speed_mph

FROM unioned_trips

-- Filter out bad records
WHERE 
    pickup_datetime IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND dropoff_datetime > pickup_datetime  -- Valid trip duration
