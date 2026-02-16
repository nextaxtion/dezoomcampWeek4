/*
    DIMENSION MODEL: dim_zones
    
    Purpose: Taxi zone lookup dimension table
    
    This demonstrates:
    1. Using seeds (ref to CSV data)
    2. Using dbt_utils package (generate_surrogate_key macro)
    3. Creating a dimension table
*/

WITH zone_lookup AS (
    SELECT * FROM {{ ref('taxi_zone_lookup') }}
)

SELECT
    -- Use dbt_utils to create a surrogate key
    {{ dbt_utils.generate_surrogate_key(['LocationID']) }} AS zone_key,
    
    LocationID AS location_id,
    Borough AS borough,
    Zone AS zone,
    service_zone,
    
    -- Add some useful flags
    CASE WHEN Borough = 'Manhattan' THEN TRUE ELSE FALSE END AS is_manhattan,
    CASE WHEN service_zone = 'Yellow Zone' THEN TRUE ELSE FALSE END AS is_yellow_zone
    
FROM zone_lookup
