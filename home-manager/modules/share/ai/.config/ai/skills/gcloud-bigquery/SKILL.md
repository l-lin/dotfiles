---
name: gcloud-bigquery
description: Use when querying or investigating BigQuery data from the terminal with the Google Cloud CLI, especially when the project, dataset location, table schema, scan cost, or query result needs verification.
disable-model-invocation: false
---

1. Query the right scope. Confirm the question, billing project, dataset location, and source tables. Check the active account and project without changing `gcloud` configuration. The BigQuery command bundled with the Google Cloud CLI is `bq`; `gcloud bq query` is not a query command.
2. Verify before writing SQL. Inspect unfamiliar table metadata and schemas. Use fully qualified table names, and never guess fields, types, partitions, or locations.
3. Query read-only data. Use GoogleSQL and explicit `--project_id` and `--location` flags. Reject DDL, DML, exports, IAM changes, and other mutations. Dry-run every data-scanning query, then execute it with a scan cap and bounded output.
4. Verify the result. Check that filters, time boundaries, row counts, nulls, grouping grain, and units answer the stated question. Treat zero rows as a result to investigate, not proof that no data exists.
5. Summarize the evidence. Report the project, location, tables, time range, scan estimate, decisive result, and caveats. Include reusable SQL or the exact command when useful, but do not dump large result sets.
6. Use `references/QUERIES.md` for command templates, parameters, structured output, and verification queries.
