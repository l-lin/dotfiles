# Latency and SLO triage

## Unit and tag traps

Check these before you compare a value to an SLO threshold.

- APM span durations, such as `custom.duration` or `@duration`, are in nanoseconds. `1s = 1e9 ns`.
- APM metrics, such as `trace.servlet.request` or `trace.postgresql.query`, are in seconds. A value of `0.04` means 40 ms.
- `trace.*` metrics are often tagged by `base_service:` instead of `service:`. If `service:` returns no series, retry with `base_service:`.
- JVM and runtime metrics are sometimes missing. Treat garbage collection as a blind spot and infer it from traces.

## Triage sequence

1. Prove the SLO definition. Run `pup slos get <SLO_ID>`. Record the exact metric, threshold, and `query_interval_seconds`. Match your rollup to that window, for example `.rollup(max,300)` for a 5 minute p99 SLO.
2. Prove the slow window. Query the SLO metric over time and record the exact UTC minutes. If a wide `--from` and `--to` range hides the spike, narrow the range with ISO8601 timestamps so Datadog uses smaller buckets.
3. Prove where the time went. Search for slow traces, sort by duration, then fetch sibling spans by `trace_id`.

```bash
pup traces search --query '... @duration:>150000000' --limit 30
```

4. Prove or clear each likely cause.
   - Rollout or deploy: group a pod metric by `kube_replica_set` across several days. A new replicaset marks a deploy. Slow traces from a stable, already-running replicaset clear the rollout.
   - DB compute: check `aws.rds.cpuutilization`, `buffer_cache_hit_ratio`, `deadlocks`, `commit_latency`, and IOPS by `dbinstanceidentifier`. An idle instance plus a slow query span points to a lock, network delay, or connection path issue, not compute.
   - Kubernetes CPU throttling: inspect `kubernetes.cpu.cfs.throttled.periods` and `kubernetes.cpu.cfs.throttled.seconds`. Any nonzero value means throttling.
   - Burst against stall: compare request or query rate in the same window with `trace.*.hits` and `.as_count()`. A burst raises the rate. A shared stall lowers the completed rate while latency climbs.
   - Per-pod pause against shared dependency: group slow traces by `pod_name`, `start_timestamp`, and `end_timestamp`. All pods slowing at once points to a shared dependency. Many in-flight requests on one pod ending together points to a stop-the-world pause on that pod.
5. Prove the caller. Search client spans with the path and exclude the server service.

```bash
pup traces search --query '@http.url:*<path>* -service:<server>'
```
