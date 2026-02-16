/*
    SNAPSHOT: snap_zones
    
    Purpose: Track changes to taxi zones over time
    
    What this does:
    - Takes a "picture" of dim_zones every time you run dbt snapshot
    - If a zone's borough or service_zone changes, it creates a new record
    - Keeps history with dbt_valid_from and dbt_valid_to timestamps
    
    Example: If Zone 5 changes from "Boro Zone" to "Yellow Zone":
    - Old record gets dbt_valid_to = timestamp of change
    - New record gets created with dbt_valid_from = timestamp of change
*/

{% snapshot snap_zones %}

{{
    config(
      target_schema='dezoomcampDBT',
      unique_key='location_id',
      strategy='check',
      check_cols=['borough', 'service_zone'],
    )
}}

-- Select the current state of zones
SELECT 
    location_id,
    borough,
    zone,
    service_zone
FROM {{ ref('dim_zones') }}

{% endsnapshot %}
