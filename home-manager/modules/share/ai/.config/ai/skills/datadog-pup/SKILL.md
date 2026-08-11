---
name: datadog-pup
description: Use when interacting with Datadog resources using the `pup` CLI, especially for APM traces, metrics, monitors, notebooks, and synthetic tests.
disable-model-invocation: false
---

1. Scope first. Confirm the org and team before broad queries or lists.
   - If results look wrong, run `pup auth status`. If needed, use `pup auth login --org monolith` or add `--org monolith`.
   - On `p3c`, filter shared resources before listing. Use monitor tags like `team:p3c` and log queries like `team:p3c service:<service>`.
2. Prove it. For incidents, read the source of truth, narrow the time window, then inspect traces or metrics.
   - For latency or SLO work, follow `references/LATENCY-SLO-TRIAGE.md`.
   - Remember the unit trap: APM span durations are nanoseconds, APM metrics are seconds, and `trace.*` metrics may need `base_service:` instead of `service:`.
3. Mutate safely. Search or list before acting, then `get`, then export JSON before `create`, `update`, or `delete`.
   - Prefer `--agent` when you need structured output.
   - Use `-y` only when automation truly needs a non-interactive delete.
4. Reach for the right reference.
   - Use `references/COMMANDS.md` for command patterns across traces, metrics, monitors, logs, synthetics, notebooks, SLOs, dashboards, incidents, and discovery.
   - Treat missing JVM or runtime metrics as a blind spot, not proof that nothing happened.
