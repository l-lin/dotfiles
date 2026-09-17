# BigQuery query patterns

Use `bq`, which is installed with the Google Cloud CLI. Keep project and location explicit so local defaults cannot redirect billing or jobs.

## Check context

```bash
gcloud auth list --filter='status:ACTIVE' --format='value(account)'
gcloud config get project
```

If either value is missing or unexpected, stop and ask the user which account or project to use. Do not run `gcloud config set` for them.

## Inspect a table

BigQuery CLI resource names use `PROJECT:DATASET.TABLE`:

```bash
bq \
  --project_id="$PROJECT_ID" \
  --location="$LOCATION" \
  --format=prettyjson \
  show \
  --schema \
  "$PROJECT_ID:$DATASET.$TABLE"
```

For partitioning, clustering, row count, and full metadata, omit `--schema`.

## Dry-run and execute

Write multiline SQL without shell interpolation:

```bash
SQL="$(cat <<'SQL'
SELECT
  event_date,
  COUNT(*) AS event_count
FROM `source-project.dataset.events`
WHERE event_date BETWEEN @start_date AND @end_date
GROUP BY event_date
ORDER BY event_date
SQL
)"
```

Validate the SQL and estimate bytes processed:

```bash
bq \
  --project_id="$PROJECT_ID" \
  --location="$LOCATION" \
  --format=prettyjson \
  query \
  --dry_run=true \
  --use_legacy_sql=false \
  --parameter="start_date:DATE:$START_DATE" \
  --parameter="end_date:DATE:$END_DATE" \
  "$SQL"
```

Execute only after the dry run succeeds. Set `MAXIMUM_BYTES_BILLED` to an accepted ceiling at or above the estimate:

```bash
bq \
  --project_id="$PROJECT_ID" \
  --location="$LOCATION" \
  --format=json \
  query \
  --use_legacy_sql=false \
  --maximum_bytes_billed="$MAXIMUM_BYTES_BILLED" \
  --max_rows=100 \
  --parameter="start_date:DATE:$START_DATE" \
  --parameter="end_date:DATE:$END_DATE" \
  "$SQL"
```

Use `--format=pretty` for quick human inspection, `--format=json` for programmatic checks, and `--format=csv` for compact tabular output. Keep `--max_rows` low unless the user needs raw rows.

Parameter syntax is `NAME:TYPE:VALUE`. Use an empty name for positional parameters. Prefer named parameters over interpolating values into SQL.

## Verification queries

Check the available time range before interpreting an empty result:

```sql
SELECT
  MIN(event_date) AS first_date,
  MAX(event_date) AS last_date,
  COUNT(*) AS row_count
FROM `project.dataset.table`
```

Check null coverage for decisive fields:

```sql
SELECT
  COUNT(*) AS row_count,
  COUNTIF(key_field IS NULL) AS null_key_count
FROM `project.dataset.table`
WHERE event_date BETWEEN @start_date AND @end_date
```

Check whether joins changed the intended grain:

```sql
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT business_key) AS distinct_key_count
FROM (
  -- Read-only query under investigation.
)
```

Add partition filters as early as possible. Select only needed columns. Use `LIMIT` to bound returned rows, not as a substitute for partition or predicate filters because it does not reliably reduce bytes scanned.
