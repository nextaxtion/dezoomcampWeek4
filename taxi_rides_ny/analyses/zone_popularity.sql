/*
    ANALYSIS: Zone Popularity
    
    Purpose: Which zones have the most pickups/dropoffs
    
    This uses the dim_zones dimension table to enrich the analysis
*/

WITH pickup_counts AS (
    SELECT
        pickup_location_id AS location_id,
        COUNT(*) AS pickup_count
    FROM {{ ref('fact_trips') }}
    GROUP BY 1
),

dropoff_counts AS (
    SELECT
        dropoff_location_id AS location_id,
        COUNT(*) AS dropoff_count
    FROM {{ ref('fact_trips') }}
    GROUP BY 1
)

SELECT
    z.location_id,
    z.borough,
    z.zone,
    z.service_zone,
    COALESCE(p.pickup_count, 0) AS pickup_count,
    COALESCE(d.dropoff_count, 0) AS dropoff_count,
    COALESCE(p.pickup_count, 0) + COALESCE(d.dropoff_count, 0) AS total_trips
FROM {{ ref('dim_zones') }} z
LEFT JOIN pickup_counts p ON z.location_id = p.location_id
LEFT JOIN dropoff_counts d ON z.location_id = d.location_id
ORDER BY total_trips DESC
