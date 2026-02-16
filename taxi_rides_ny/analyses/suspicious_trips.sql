/*
    ANALYSIS: Data Quality Check - Suspicious Trips
    
    Purpose: Find potentially invalid trip records
    
    Use for: Data quality investigations, outlier detection
*/

SELECT
    service_type,
    pickup_datetime,
    trip_distance,
    trip_duration_minutes,
    total_amount,
    avg_speed_mph,
    
    -- Flag suspicious patterns
    CASE
        WHEN avg_speed_mph > 100 THEN 'Speed too high'
        WHEN trip_distance > 100 THEN 'Distance too far'
        WHEN total_amount > 1000 THEN 'Fare too high'
        WHEN trip_duration_minutes > 300 THEN 'Trip too long'
        ELSE 'OK'
    END AS data_quality_flag
    
FROM {{ ref('fact_trips') }}
WHERE 
    avg_speed_mph > 100
    OR trip_distance > 100
    OR total_amount > 1000
    OR trip_duration_minutes > 300
ORDER BY avg_speed_mph DESC
LIMIT 50
