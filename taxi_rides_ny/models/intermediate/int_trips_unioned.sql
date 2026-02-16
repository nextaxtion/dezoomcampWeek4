/*
    INTERMEDIATE MODEL: int_trips_unioned
    
    Purpose: Combine green and yellow taxi data into one unified dataset
    
    What this model does:
    1. References BOTH staging models using ref()
    2. Unions them together (stacking rows)
    3. Creates a single dataset with all taxi trips
    
    Important concept: ref() creates model dependencies
    - dbt knows this model depends on stg_green_tripdata and stg_yellow_tripdata
    - dbt will run those models FIRST before running this one
    - This is the "DAG" (Directed Acyclic Graph) in action!
*/

-- Step 1: Get green taxi data
WITH green_trips AS (
    SELECT * FROM {{ ref('stg_green_tripdata') }}
),

-- Step 2: Get yellow taxi data  
yellow_trips AS (
    SELECT * FROM {{ ref('stg_yellow_tripdata') }}
)

-- Step 3: Stack them together
-- UNION ALL keeps all rows (including duplicates if any)
-- The columns must match in both tables
SELECT * FROM green_trips
UNION ALL
SELECT * FROM yellow_trips
