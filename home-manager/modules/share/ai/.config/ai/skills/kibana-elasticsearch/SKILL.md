---
name: kibana-elasticsearch
description: Use when querying Elasticsearch through the Kibana console proxy, especially for log investigations, field-based filtering, or error triage from job or application logs.
disable-model-invocation: false
---

1. Check access first. Verify `ES_API_KEY` and `KIBANA_URL` are set without printing their values. If Cloudflare Access may apply, verify `cloudflared` is available and authenticated. If access is missing, stop and ask the user to fix it before querying.
2. Discover fields first. On an unfamiliar index or pattern, fetch mappings before writing queries. Do not guess field names, nested paths, or `text` versus `keyword` variants.
3. Query narrowly first. Start with the smallest useful time window, explicit `_source` fields, and sorted timestamps. Prefer wildcard index patterns like `logs*` or `jobs*`. Remember the proxy path must URL-encode `/` as `%2F`.
4. Prove the result. Report the index pattern, time window, decisive fields, and a small excerpt or count that supports the conclusion. If nothing matches, say whether access, mappings, time range, or filters are the likely gap.
5. Reach for the reference. Use `references/COMMANDS.md` for access checks, proxy command templates, mapping discovery, and query patterns.
