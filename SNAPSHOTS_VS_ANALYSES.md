# Snapshots vs Analyses - Quick Reference

## 1. SNAPSHOTS (Slowly Changing Dimensions)

### What They Are:
- **Special tables** that track historical changes over time
- Implements **SCD Type 2** (Slowly Changing Dimension)
- Automatically adds meta columns: `dbt_valid_from`, `dbt_valid_to`, `dbt_updated_at`

### When to Use:
- Track how dimension data changes (e.g., customer addresses, product prices, zone classifications)
- Audit trail requirements
- Time-travel analysis ("What was the price on Jan 1st?")

### Key Configuration:
```sql
{% snapshot snap_name %}
{{
    config(
      target_schema='your_schema',
      unique_key='id_column',              -- Primary key
      strategy='check',                     -- or 'timestamp'
      check_cols=['col1', 'col2'],         -- Columns to monitor for changes
    )
}}
SELECT * FROM {{ ref('source_model') }}
{% endsnapshot %}
```

### How It Works:
**First run:** Creates table with all current records
```
location_id | borough | dbt_valid_from      | dbt_valid_to
1           | Queens  | 2026-02-15 09:48:29 | NULL
```

**Second run (after data changes):** 
- Old record gets `dbt_valid_to` = current timestamp
- New record gets created with `dbt_valid_from` = current timestamp

```
location_id | borough    | dbt_valid_from      | dbt_valid_to
1           | Queens     | 2026-02-15 09:48:29 | 2026-02-16 10:00:00  ← Ended
1           | Manhattan  | 2026-02-16 10:00:00 | NULL                 ← Current
```

### Commands:
- `dbt snapshot` - Run all snapshots
- `dbt snapshot --select snap_zones` - Run specific snapshot

### Location:
- Files go in: `snapshots/` folder
- Tables created in: Your target schema (e.g., `dezoomcampDBT.snap_zones`)

---

## 2. ANALYSES (Ad-hoc Queries)

### What They Are:
- **SQL queries** that dbt compiles but does NOT materialize
- No tables/views created
- Used for one-time analysis, reports, investigations

### When to Use:
- Data exploration queries
- One-time reports
- Data quality investigations
- Queries you want to version control but not run automatically
- SQL for BI tools or Jupyter notebooks

### How It Works:
1. Write SQL in `analyses/` folder (can use `ref()` and `source()`)
2. Run `dbt compile` 
3. Find compiled SQL in `target/compiled/taxi_rides_ny/analyses/`
4. Copy SQL to BigQuery console, Jupyter, or BI tool
5. Run manually whenever needed

### Key Difference from Models:
```
Models (models/)          →  dbt run  →  Creates tables/views in warehouse
Analyses (analyses/)      →  dbt compile  →  Just generates SQL (no tables created)
```

### Location:
- Files go in: `analyses/` folder
- Compiled SQL in: `target/compiled/taxi_rides_ny/analyses/`
- **Nothing created in BigQuery** (you run the SQL manually)

---

## Comparison Table

| Feature | Snapshots | Analyses |
|---------|-----------|----------|
| **Purpose** | Track historical changes | Ad-hoc analysis queries |
| **Materialization** | Table (with history) | None (SQL only) |
| **Command** | `dbt snapshot` | `dbt compile` (then manual) |
| **Auto-runs in `dbt build`?** | Yes | No |
| **Folder** | `snapshots/` | `analyses/` |
| **Use `ref()`/`source()`?** | Yes | Yes |
| **Creates DB objects?** | Yes (tables) | No |
| **Version controlled?** | Yes | Yes |
| **Typical use** | Dimension history | Reports, investigations |

---

## Your Project Now Has:

### Snapshots:
- ✅ `snap_zones.sql` - Tracks zone changes over time

### Analyses:
- ✅ `revenue_by_hour.sql` - Revenue analysis by hour
- ✅ `suspicious_trips.sql` - Data quality checks
- ✅ `zone_popularity.sql` - Popular pickup/dropoff zones

### How to Use Them:

**Snapshots:**
```bash
# Run snapshot (do this daily/weekly)
dbt snapshot

# Check the history
SELECT * FROM dezoomcampDBT.snap_zones 
WHERE location_id = 1
ORDER BY dbt_valid_from;
```

**Analyses:**
```bash
# Compile to get runnable SQL
dbt compile

# View compiled SQL
cat target/compiled/taxi_rides_ny/analyses/revenue_by_hour.sql

# Copy SQL and run in BigQuery console or BI tool
```

---

## Pro Tips:

### Snapshots:
- Run regularly (daily in production) to capture changes
- **Don't modify** snapshot tables directly - dbt manages them
- Use for dimensions, not facts (facts don't "change", they're historical by nature)
- Great for auditing: "Who changed what, when?"

### Analyses:
- Perfect for exploratory work before creating a permanent model
- Share compiled SQL with analysts who don't know dbt
- Good for one-time client requests
- Can be promoted to models later if needed regularly

---

## Next Steps:

Your dbt project is now **production-ready** with:
- ✅ 6 models (staging → intermediate → marts)
- ✅ 1 seed (zone lookup)
- ✅ 1 snapshot (zone history)
- ✅ 3 analyses (ad-hoc queries)
- ✅ 10 tests
- ✅ Full documentation
- ✅ Packages (dbt_utils)

**You're ready for the homework!** 🎉
