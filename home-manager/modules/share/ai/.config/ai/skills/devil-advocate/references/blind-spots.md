# Engineering Blind Spots

Categories of issues that engineers consistently miss during design, implementation, and review. For each category: what it is, why it gets missed, key questions to surface it, and concrete examples.

---

## 1. Security

### Why It's Missed

Security is invisible when it works. Engineers optimize for functionality — "does it do the thing?" — and security failures only manifest under adversarial conditions that normal testing doesn't simulate. Security thinking requires assuming malicious intent, which is psychologically unnatural for builders.

### Key Questions

| Area | Question |
|------|----------|
| Authentication | "What happens if the JWT is expired but the request is already in flight?" |
| Authorization | "Can user A access user B's resources by changing the ID in the URL?" |
| Input validation | "What happens if this field contains 10MB of data? SQL? JavaScript? Unicode control characters?" |
| Data exposure | "What fields in this API response should the requesting user NOT see?" |
| Secrets | "If this log line is captured, does it contain anything sensitive?" |
| CSRF/SSRF | "Can this endpoint be triggered by a malicious page the user visits?" |
| Rate limiting | "What's the cost if someone calls this endpoint 10,000 times per second?" |
| Dependency | "When was the last security audit of this dependency? Does it have known CVEs?" |

### Common Misses

- **Broken object-level authorization (BOLA):** The #1 API vulnerability. Endpoint checks authentication but not whether the authenticated user owns the requested resource. Every endpoint that takes an entity ID must verify ownership.
- **Mass assignment:** Accepting all fields from request body and passing to ORM update. User sends `{"role": "admin"}` in a profile update.
- **Verbose error messages:** Stack traces, SQL errors, or internal paths in production API responses.
- **Insecure direct object references:** Sequential integer IDs that allow enumeration. User iterates `/api/invoices/1`, `/api/invoices/2`, etc.
- **Missing security headers:** No CSP, no HSTS, no X-Frame-Options in responses.

---

## 2. Scalability

### Why It's Missed

Systems that work at current scale feel correct. Engineers test with small datasets and low concurrency. The mental model of "it works" is formed at development scale and rarely updated. Scaling failures are nonlinear — a query that takes 50ms with 1,000 rows takes 30 seconds with 1,000,000.

### Key Questions

| Area | Question |
|------|----------|
| Data growth | "What happens to this query when the table has 10M rows? 100M?" |
| Traffic | "If traffic increases 10x, which component fails first?" |
| Storage | "How much storage does this consume per user per month? What's the projection?" |
| Cardinality | "How many distinct values will this column/index/cache key have?" |
| Fan-out | "How many downstream calls does a single user action trigger?" |
| Cost | "What's the cloud cost of this at 100x current usage?" |
| Hotspots | "Is there a single row, key, or partition that gets disproportionate traffic?" |

### Common Misses

- **N+1 queries:** Fetching a list then querying each item individually. Works with 10 items, catastrophic with 10,000.
- **Unbounded queries:** `SELECT * FROM table` with no LIMIT. Works in dev (100 rows), OOM in production (10M rows).
- **Missing pagination:** Endpoints that return all results. Fine until the dataset grows.
- **Full table scans disguised by small data:** Missing index on a filter column. Invisible until the table grows.
- **Cache stampede:** Cache expires, 1,000 concurrent requests all miss cache and hit database simultaneously.
- **Linear algorithms on growing data:** O(n) loops that become O(n^2) when nested or applied to growing collections.

---

## 3. Data Lifecycle

### Why It's Missed

Engineers focus on data creation and reading. The full lifecycle — creation, transformation, archival, deletion, compliance — is rarely considered upfront. Data deletion is especially neglected because it has no immediate user-facing value.

### Key Questions

| Area | Question |
|------|----------|
| Creation | "What validates this data at the point of entry? What if validation rules change?" |
| Retention | "How long do we keep this? Is there a legal or business requirement?" |
| Deletion | "If a user requests account deletion, what happens to their data across all tables?" |
| Cascade | "If this record is deleted, what references it? Do foreign keys cascade or orphan?" |
| PII | "Which fields in this table are personally identifiable? Can they be pseudonymized?" |
| Backup | "If we restore from backup, does this data have consistency dependencies with other systems?" |
| Migration | "If the schema changes, what happens to existing data? Is backfill needed?" |
| Export | "Can the user export their data? In what format?" |

### Common Misses

- **Orphaned records:** Parent deleted, children remain with dangling foreign keys or no FK at all.
- **Soft-delete inconsistency:** Some queries filter `deleted_at IS NULL`, others don't. Deleted data leaks into results.
- **PII in logs:** Structured logging captures request bodies containing email, phone, address.
- **No data retention policy:** Tables grow forever. Old data never archived or purged.
- **GDPR right-to-erasure gaps:** User deleted from `users` table but their data persists in `audit_log`, `analytics_events`, `email_log`, exported CSVs, and third-party integrations.
- **Temporal data confusion:** "Current" state mixed with historical state. No clear distinction between "active record" and "snapshot at time T."

---

## 4. Integration Points

### Why It's Missed

Engineers test their own code, not the boundary between their code and external systems. Integrations work in dev (where the external system is mocked or always-available) and fail in production (where it's flaky, slow, or returns unexpected responses).

### Key Questions

| Area | Question |
|------|----------|
| Availability | "What happens when this dependency is down for 30 minutes? 4 hours?" |
| Latency | "What if this API call takes 30 seconds instead of 200ms?" |
| Response shape | "What if the response includes fields we don't expect? Or is missing fields we do?" |
| Versioning | "What happens if the third-party API changes without notice?" |
| Rate limits | "Does this integration have rate limits? What happens when we hit them?" |
| Retry safety | "Is this operation idempotent? What happens if we retry and the first attempt actually succeeded?" |
| Blast radius | "If this integration fails, what else breaks? Can we degrade gracefully?" |
| Authentication | "When does the API token expire? What refreshes it? What if refresh fails?" |

### Common Misses

- **Timeout misconfiguration:** Default HTTP timeout of 30s or infinity. A slow dependency blocks threads, cascading to full system unavailability.
- **No circuit breaker:** Failed dependency called repeatedly, consuming resources and slowing everything.
- **Webhook delivery assumptions:** Assuming webhooks arrive once, in order, and promptly. In reality: duplicates, out-of-order, delayed by hours.
- **Schema coupling:** Deserializing the entire response into a strict type. Any field addition or type change in the external API causes failures.
- **Missing fallback:** No cached/default response when integration is unavailable. Feature becomes completely non-functional.

---

## 5. Failure Modes

### Why It's Missed

Engineers think in terms of success paths. Failure handling is added as an afterthought — often just `catch (e) { log(e) }` — without considering the taxonomy of failures and appropriate responses for each.

### Key Questions

| Area | Question |
|------|----------|
| Partial failure | "What if step 3 of 5 fails? What state is the system in?" |
| Retry behavior | "If this is retried, is the result identical? Or do we get duplicates?" |
| Error propagation | "Does this error bubble up clearly, or does it get swallowed and surface as a confusing symptom elsewhere?" |
| Poison messages | "What if one message in the queue is malformed? Does it block all processing?" |
| Resource exhaustion | "What happens when disk is full? Memory is exhausted? Connection pool is depleted?" |
| Cascading failure | "If this component fails, what other components fail as a result?" |
| Recovery | "After the failure is resolved, does the system self-heal or require manual intervention?" |

### Common Misses

- **Inconsistent state from partial operations:** Multi-step process (create order, charge payment, send email) fails at step 2. Order exists, payment didn't happen, but there's no compensation logic.
- **Retry storms:** Service A retries failed calls to Service B. Service B was failing due to overload. Retries make it worse. Exponential backoff with jitter is missing.
- **Silent failures:** Exception caught and logged but not propagated. System appears healthy while producing wrong results.
- **Error message uselessness:** `"An error occurred"` with no context about what failed, why, or what the user can do about it.
- **Deadletter neglect:** Failed messages go to a dead letter queue that nobody monitors. Data is silently lost.

---

## 6. Concurrency

### Why It's Missed

Developers write and test code sequentially. Concurrency bugs are non-deterministic — they depend on timing, load, and scheduling. A race condition that occurs 1 in 10,000 times passes all tests and only manifests in production under load.

### Key Questions

| Area | Question |
|------|----------|
| Race conditions | "If two users do this simultaneously, what happens?" |
| Double-submit | "If the user clicks the button twice quickly, do we create two records?" |
| Read-modify-write | "Between reading this value and writing the update, can another process change it?" |
| Locking | "What's the lock granularity? Are we holding locks during I/O?" |
| Deadlock | "Can two processes each hold a lock the other needs?" |
| Ordering | "Does this code assume events arrive in order? What if they don't?" |
| Idempotency | "If this operation runs twice with the same input, is the result the same?" |

### Common Misses

- **Check-then-act without locking:** `if not exists(email): create_user(email)` — two concurrent requests both pass the check, both create the user.
- **Lost updates:** Two requests read balance=100, both add 50, both write 150. Expected: 200. Use optimistic locking (version column) or `UPDATE ... SET balance = balance + 50`.
- **Double-submit on forms:** User clicks "Submit" twice. Two identical records created. No idempotency key, no client-side guard.
- **Counter drift:** `count = get_count(); set_count(count + 1)` instead of atomic `INCREMENT`. Under concurrency, counts drift downward.
- **Connection pool exhaustion:** Long-running transactions or leaked connections deplete the pool. New requests queue and timeout.

---

## 7. Environment Gaps

### Why It's Missed

"Works on my machine" is the canonical expression of this blind spot. Development environments differ from production in ways that are invisible until they cause failures: different OS, different resource limits, different network topology, different data volume.

### Key Questions

| Area | Question |
|------|----------|
| Configuration | "Which config values differ between dev, staging, and production?" |
| Data volume | "Dev has 100 rows. Production has 10M. Have we tested with production-scale data?" |
| Network | "Does this assume localhost latency? What about cross-region calls in prod?" |
| Permissions | "Does the prod service account have the same permissions as the dev user?" |
| Secrets | "How are secrets managed in production? Are they the same as dev?" |
| Resource limits | "What are the memory/CPU/disk limits in production? Have we tested at those limits?" |
| Dependencies | "Are all dependency versions pinned? Could a `latest` tag differ between environments?" |
| Feature flags | "What flags are enabled in prod that aren't in dev, or vice versa?" |

### Common Misses

- **Timezone differences:** Dev machine is UTC, production is UTC, but the database server was configured in a different timezone by the cloud provider's default.
- **File system assumptions:** Code writes to `/tmp` expecting unlimited space. Production container has a 512MB tmpfs.
- **DNS resolution:** Local dev resolves service names instantly. Production DNS has TTLs, caching, and occasional failures.
- **SSL/TLS in production only:** Dev uses HTTP. First production deploy fails because the app doesn't trust the CA, or redirects break.
- **Missing environment variables:** App starts fine in dev (defaults used). Production has no defaults and crashes on startup — or worse, silently uses wrong values.

---

## 8. Observability

### Why It's Missed

Observability is not a feature users see. It has zero user-facing value until something breaks — then it's the most important thing. Engineers under time pressure deprioritize it because it doesn't show up in demos.

### Key Questions

| Area | Question |
|------|----------|
| Debugging | "If this fails in production at 3am, what information does the on-call engineer have?" |
| Logging | "Are log messages structured? Do they include correlation IDs, user IDs, and context?" |
| Metrics | "What metrics tell us this system is healthy? What threshold means 'unhealthy'?" |
| Alerting | "What alerts fire if this breaks? Are they actionable or just noise?" |
| Tracing | "Can we trace a user request across all services it touches?" |
| Dashboards | "Is there a dashboard for this feature? Does anyone actually look at it?" |
| Cost | "Do we know the per-request cost of this operation? Can we detect cost anomalies?" |

### Common Misses

- **Log and pray:** Logging exists but no one queries it. No alerts, no dashboards, no runbooks.
- **Missing request correlation:** No way to trace a single user request through multiple services and database calls.
- **Metric cardinality explosion:** Metrics tagged with user ID or request ID. Monitoring system overwhelmed.
- **Alert fatigue:** Too many non-actionable alerts. On-call ignores them all. Real alerts get lost in noise.
- **No business metrics:** Technical metrics (CPU, memory, latency) exist but no one tracks business metrics (orders per minute, conversion rate). A business failure with healthy infrastructure goes undetected.

---

## 9. Deployment

### Why It's Missed

Deployment is treated as "push code, it's live." The transition period — where old code and new code coexist, where migrations run, where caches contain old data — is rarely considered. Engineers think in terms of "before" and "after," not "during."

### Key Questions

| Area | Question |
|------|----------|
| Rollback | "Can we roll back this deployment in under 5 minutes? What breaks if we do?" |
| Migration | "Is this migration backward-compatible? Can old code work with the new schema?" |
| In-flight requests | "What happens to requests that started before deployment and finish after?" |
| Cache invalidation | "Do cached values still make sense after this deployment?" |
| Feature flags | "Can this feature be turned off without a deployment?" |
| Zero-downtime | "Is there a moment during deployment where the service is unavailable?" |
| Dependency ordering | "Does this deployment require another service to be deployed first?" |

### Common Misses

- **Non-reversible migrations:** Column renamed or dropped. Rollback to previous code version fails because the old code expects the old column.
- **Breaking API changes without versioning:** Frontend deployed before backend (or vice versa). Brief period where client and server disagree on the API contract.
- **Stale caches:** Deployment changes response format. CDN/browser/application cache serves old format. Users see broken UI until cache expires.
- **Blue/green session loss:** User is on the old instance with session state. Traffic switches to the new instance. Session gone.
- **Database migration under load:** Migration locks a table for ALTER. All queries to that table queue and timeout. Application appears down.

---

## 10. Multi-Tenancy

### Why It's Missed

Multi-tenancy is an architectural constraint that touches everything but is owned by no single feature. Each individual feature works correctly in isolation. The failures only appear when tenants interact — through shared resources, leaked data, or noisy neighbors.

### Key Questions

| Area | Question |
|------|----------|
| Data isolation | "If I remove the auth token and substitute a different tenant ID, do I see their data?" |
| Query filtering | "Does every query in this feature filter by tenant? Including joins, subqueries, and aggregations?" |
| Resource fairness | "Can one tenant's usage degrade performance for all others?" |
| Configuration | "Is this hardcoded for one tenant, or configurable per tenant?" |
| Background jobs | "Do background jobs set the tenant context? What if a job processes multiple tenants?" |
| Caching | "Are cache keys namespaced by tenant? Can tenant A's cache return tenant B's data?" |
| Logging | "If we search logs by tenant ID, do we get exactly and only their activity?" |

### Common Misses

- **Missing tenant filter in new queries:** Every new query must include `tenant_id`. One missed filter = cross-tenant data leak.
- **Global caches:** Cache key `user:123` without tenant prefix. Two tenants with user ID 123 get each other's cached data.
- **Shared rate limits:** Rate limit applied globally. One tenant's legitimate burst blocks all other tenants.
- **Tenant-specific config as code:** Feature flag or business rule hardcoded in an if-statement instead of in tenant configuration.
- **Background job context leakage:** Job processes tenant A, then tenant B, but the tenant context from A persists into B's processing.

---

## 11. Edge Cases

### Why It's Missed

Edge cases are, by definition, not the common case. Engineers build for the typical user on the typical path. But edge cases are where bugs hide, where data corrupts, and where security vulnerabilities live. The edges of the input space are also where attackers operate.

### Key Questions

| Area | Question |
|------|----------|
| Empty state | "What does this look like with zero data? First-time user, empty list, no history?" |
| Boundaries | "What happens at the maximum? Minimum? Exactly zero? Negative values?" |
| Unicode | "What happens with emoji, RTL text, or characters outside ASCII?" |
| Timezone | "What happens at midnight? What about midnight in different timezones? DST transitions?" |
| Precision | "Are we using floats for money? What happens to rounding over millions of transactions?" |
| Nulls | "Which of these fields can be null in practice, even if the schema says NOT NULL?" |
| Ordering | "What if the list is empty? One item? Already sorted? Reverse sorted?" |

### Common Misses

- **Empty state panic:** Feature works beautifully with data. With no data: blank screen, undefined errors, or misleading "No results found" when the user hasn't searched yet.
- **Integer overflow / float precision:** `0.1 + 0.2 !== 0.3` in IEEE 754. Currency calculations drift. Use integer cents or decimal types.
- **Timezone-naive datetime:** Storing `datetime` without timezone info. Comparing timestamps from different sources produces wrong results around DST.
- **Names and text assumptions:** Name field rejects O'Brien (unescaped apostrophe), Mller (umlaut), or (zero-width space). Max length of 50 rejects legitimate long names.
- **Off-by-one in pagination:** Page 1 shows items 1-10, page 2 shows items 10-19 (item 10 duplicated) or items 12-21 (item 11 missing).
- **Leap seconds, leap years, DST:** `February 29` breaks date validation. `2am on DST transition` doesn't exist (or exists twice). Scheduling logic fails.
- **Maximum payload:** File upload with no size limit. User uploads 5GB file. Server runs out of memory.

---

## Quick Reference: The Question That Catches Each Blind Spot

| Blind Spot | Single Most Revealing Question |
|------------|-------------------------------|
| Security | "Can user A access user B's data by manipulating the request?" |
| Scalability | "What happens at 100x current scale?" |
| Data lifecycle | "If we delete this user, what happens to their data everywhere?" |
| Integration | "What happens when this dependency is down for an hour?" |
| Failure modes | "If step 3 of 5 fails, what state is the system in?" |
| Concurrency | "If two users do this at the exact same time, what happens?" |
| Environment | "What's different about production that we're not testing?" |
| Observability | "Can the on-call engineer debug this at 3am with available tools?" |
| Deployment | "Can we roll this back in 5 minutes without data loss?" |
| Multi-tenancy | "Does every query filter by tenant, including this new one?" |
| Edge cases | "What does this look like with zero data? Maximum data? Unicode?" |
