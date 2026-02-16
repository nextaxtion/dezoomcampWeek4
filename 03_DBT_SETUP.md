# STEP 3: dbt Core Setup & BigQuery Connection
## Building From Scratch - Learning Mode

**Status**: ✅ COMPLETE

---

## WHAT WE ACCOMPLISHED

### 1. Installed dbt Core
```bash
# Created virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Installed dbt-bigquery
pip install dbt-bigquery
```

**Version**: dbt Core 1.11.4 with BigQuery adapter 1.11.0

---

### 2. Created dbt Profile (Connection to BigQuery)

**File**: `~/.dbt/profiles.yml`

```yaml
taxi_rides_ny:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: dezoomcamp-486216
      dataset: dezoomcampDBT
      keyfile: /home/nextaxtion/deZoomcampWeek2/secrets/gcp-key.json
      threads: 4
      timeout_seconds: 300
      location: us-central1
```

**Key settings**:
- **Project**: dezoomcamp-486216 (your GCP project)
- **Dataset**: dezoomcampDBT (where dbt will write transformed tables)
- **Location**: us-central1 (matches your raw data location)
- **Auth**: Service account JSON key from Week 2

---

### 3. Verified Connection

```bash
dbt debug
```

**Result**: ✅ All checks passed! Connection to BigQuery working.

---

## YOUR ENVIRONMENT SUMMARY

```
Raw Data (Week 3):
├─ Project: dezoomcamp-486216
├─ Dataset: dezoomcampds
├─ Location: us-central1
└─ Tables: green_tripdata, yellow_tripdata

dbt Output (Week 4):
├─ Project: dezoomcamp-486216  
├─ Dataset: dezoomcampDBT
├─ Location: us-central1
└─ Tables: (dbt will create these)
```

---

## NEXT STEP

Now we'll **initialize a dbt project from scratch** and build it step by step, following the trainer's approach.

Ready when you are!
