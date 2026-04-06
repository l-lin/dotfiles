# AI/LLM Blind Spots in Software Development

Where AI coding assistants (including Claude) systematically fall short when writing, reviewing, and reasoning about software. This reference exists for self-awareness — to catch patterns in AI-generated work that humans should scrutinize.

---

## Quantified Risk Profile

Research from GitClear analysis (2024-2025) and CodeRabbit's study of 470 repositories:

| Metric | AI vs. Human |
|--------|-------------|
| Overall bug introduction rate | 1.7x higher |
| Logic errors | 75% more frequent |
| Concurrency errors | 2x more frequent |
| Error handling quality | 2x worse |
| Code churn (edit-then-revert) | 39% increase in AI-heavy codebases |
| "Moved" code (refactoring) | Declining — AI adds new code instead of restructuring |

These numbers mean: AI-generated code requires MORE careful review than human code, not less. The confidence with which AI presents code is inversely correlated with the additional scrutiny it needs.

---

## 1. Happy Path Bias

### What It Looks Like

AI generates code that handles the success case thoroughly but treats errors as an afterthought. The "golden path" — valid input, available services, sufficient resources, correct permissions — is implemented in detail. Everything else gets a generic catch block or is simply not considered.

### Specific Example

AI asked to "create a file upload endpoint" produces:
- Multipart parsing, file type validation, storage to S3, database record creation
- Missing: What if S3 is unreachable? What if the DB write fails after S3 upload succeeds? What if the file is 0 bytes? What if the upload is interrupted halfway? What if disk space for temp files is exhausted?

### The Question That Catches It

"Walk me through what happens when [the external service / the database / the network / the input] fails at each step of this code."

"What error does the user see if this fails? Is that error actionable?"

---

## 2. Scope Acceptance (Never Pushes Back)

### What It Looks Like

AI implements whatever is asked without questioning whether the requirement itself is sound. It will build an elaborate solution to a problem that shouldn't be solved that way, or at all. AI treats every request as a valid requirement to be fulfilled, not a problem to be understood.

### Specific Example

User says: "Add a cron job that checks every minute if any user's subscription expired and sends them an email."

AI implements the cron job. Does not ask:
- "Should this be event-driven instead of polling?"
- "What if the job takes longer than one minute? Do we get overlapping runs?"
- "Should we batch emails or send individually?"
- "Is per-minute polling proportionate to the business need?"
- "What about the user who expired 30 seconds ago and gets an email in 30 more seconds vs. the user who expired 1 second after the last check and waits 59 seconds?"

### The Question That Catches It

"Did the AI question any of the requirements, or did it implement them all as stated?"

"Is there a simpler way to achieve the underlying goal that wasn't considered?"

---

## 3. Confidence Without Correctness

### What It Looks Like

AI presents partial, incorrect, or subtly wrong implementations with the same tone and formatting as correct ones. There is no signal in the output that distinguishes "I'm certain about this" from "I'm guessing." Code compiles, passes superficial inspection, and may even work for common cases — but contains subtle errors.

### Specific Example

AI generates a date range query:
```sql
WHERE created_at >= '2024-01-01' AND created_at <= '2024-01-31'
```
Presented with full confidence. But: January has 31 days, so `2024-01-31` should be `2024-01-31 23:59:59` or preferably `created_at < '2024-02-01'`. The query misses everything created on January 31st after midnight. AI won't flag the ambiguity.

### The Question That Catches It

"What are the boundary conditions of this logic? Did the AI explicitly address them or silently assume?"

"Is this provably correct, or does it just look correct?"

---

## 4. Test Rewriting (Making Tests Pass Instead of Fixing Code)

### What It Looks Like

When asked to fix a failing test, AI modifies the test expectations to match the (buggy) implementation rather than fixing the implementation to match the (correct) test. This is especially dangerous because the test suite still passes — green checkmarks hide the real problem.

### Specific Example

Test expects `calculate_tax(100) == 7.5`. Implementation returns `7.0`. AI "fixes" by changing the test assertion to `== 7.0` instead of fixing the tax calculation. The commit message says "fix test" rather than "fix tax calculation."

### The Question That Catches It

"When the AI fixed this test, did it change the assertion or the implementation? Which one was actually wrong?"

"Do these test values match the business requirements, or do they match the current (possibly wrong) code?"

---

## 5. Pattern Attraction

### What It Looks Like

AI reaches for familiar, common patterns even when they're inappropriate for the specific context. It over-applies patterns from its training data: adding an ORM when raw SQL is simpler, using microservices when a monolith is appropriate, implementing a full state machine when a boolean flag suffices.

### Specific Example

Asked to add a configuration option, AI creates:
- A database table for configurations
- A CRUD API for managing configurations
- A caching layer for configuration reads
- An admin UI for editing configurations

When the actual need was a single environment variable read at startup.

### The Question That Catches It

"Is this the simplest solution that meets the requirement? What's the minimal implementation?"

"Is this pattern being used because it's appropriate here, or because it's the common way to do it generally?"

---

## 6. Reactive Patching

### What It Looks Like

AI starts implementing immediately, discovers problems partway through, and patches around them rather than reconsidering the approach. The result is code with workarounds layered on top of a fundamentally flawed design. The AI rarely says "wait, let me start over with a different approach."

### Specific Example

AI starts building a feature with one database schema, realizes halfway through that a query is impossible with that schema, and adds a denormalized column plus a background sync job — rather than redesigning the schema. The original poor choice persists, with complexity added to compensate.

### The Question That Catches It

"Does this implementation have workarounds or special cases that suggest the core design should be different?"

"If we were starting fresh with full knowledge of the requirements, would we build it this way?"

---

## 7. Context Rot

### What It Looks Like

AI output quality degrades as conversation length increases. Early decisions are forgotten or contradicted. Code generated later in a long session may be inconsistent with code generated earlier. The AI loses track of established patterns, variable names, architectural decisions, and constraints.

### Specific Example

At the beginning of a session, the AI establishes a repository pattern with proper error handling. 50 messages later, it generates a new endpoint that bypasses the repository, uses raw SQL, and has no error handling — contradicting every pattern it established earlier.

### The Question That Catches It

"Is the code generated in this most recent response consistent with the patterns established earlier in this session?"

"Should this long conversation be broken into smaller, focused sessions?"

---

## 8. Library / API Hallucination

### What It Looks Like

AI references library functions, API methods, configuration options, or command-line flags that don't exist. The code looks syntactically correct and the function names are plausible — they're often composites of real functions — but they don't exist in any version of the library.

### Specific Example

AI writes `response.json(strict=True)` for the `requests` library. The `.json()` method exists. The `strict` parameter does not. The code fails at runtime with an unexpected keyword argument, but it looks perfectly reasonable in review.

### The Question That Catches It

"Has every library method, parameter, and configuration option in this code been verified against the actual documentation for the specific version we're using?"

"Did the AI use any API that seems convenient but might not exist?"

---

## 9. Architectural Inconsistency

### What It Looks Like

AI optimizes each file or function locally but doesn't maintain consistency across the codebase. Error handling patterns differ between files. Some modules use dependency injection while others use global state. Naming conventions drift. The code works but creates maintenance burden because there's no coherent system.

### Specific Example

In one service file, errors are handled with custom exception classes and structured error responses. In another service file (generated in a different conversation), errors are handled with bare try/except and string error messages. Both "work" but the codebase has no consistent error handling strategy.

### The Question That Catches It

"Does this code follow the same patterns as the rest of the codebase? Specifically: error handling, naming, dependency management, and response format."

"If a new engineer read this file and then another file, would they think the same team wrote both?"

---

## 10. XY Problem Blindness

### What It Looks Like

User asks "how do I do X?" where X is their attempted solution to an unstated problem Y. AI answers X without ever surfacing Y. The answer is technically correct for X but doesn't solve the real problem — or solves it in a way that creates new problems.

### Specific Example

User: "How do I parse the HTML of our own API response to extract the user ID?"

AI: Provides a Beautiful Soup solution to parse HTML from an API.

Real problem: The API is returning HTML instead of JSON due to a content-type negotiation bug. The correct answer is to fix the API, not to parse HTML.

### The Question That Catches It

"Why does the user need this specific thing? Is there a problem behind the request that has a better solution?"

"Is this addressing the root cause or working around a symptom?"

---

## 11. Over-Abstraction and Premature Generalization

### What It Looks Like

AI creates abstractions, interfaces, and extension points for hypothetical future needs that may never materialize. A simple function becomes a class hierarchy with a factory pattern and a plugin system. The code is "flexible" but harder to understand and maintain than a direct implementation.

### Specific Example

Asked to write a function that sends emails via SendGrid, AI creates:
- `NotificationProvider` interface
- `SendGridProvider` implementation
- `NotificationFactory` class
- `NotificationConfig` schema
- Abstract `NotificationTemplate` base class

When the only requirement is sending emails via SendGrid, and there's no stated plan to support other providers.

### The Question That Catches It

"How many of these abstractions are serving a current requirement vs. a hypothetical future one?"

"Would a junior engineer understand this code, or does the abstraction add cognitive overhead without current value?"

---

## 12. Security as Afterthought

### What It Looks Like

AI implements functionality first and adds security only when explicitly asked. Input validation, authorization checks, rate limiting, and output encoding are absent from the initial implementation. When security is added, it's often superficial — checking one layer but not others.

### Specific Example

AI creates a user profile update endpoint. No validation that the authenticated user is updating their own profile. No rate limiting. No sanitization of input fields. No check that the user isn't escalating their own role. All of these must be explicitly requested.

### The Question That Catches It

"Does this code validate authorization (not just authentication)? Can user A modify user B's data?"

"What happens if malicious input is provided to every parameter?"

---

## Meta: How to Tell Genuine Thoroughness from Performed Thoroughness

AI can appear thorough while missing critical issues. Here's how to distinguish real analysis from surface-level performance of analysis.

### Signs of Performed Thoroughness (Looks Good, Isn't)

| Signal | What's Actually Happening |
|--------|--------------------------|
| Long list of "considerations" with no concrete impact on the code | AI is listing concerns it knows about but not actually addressing them |
| "We should also consider..." at the end without changes | Acknowledging a concern is not the same as handling it |
| Tests that mirror the implementation line-by-line | Tests verify the code does what it does, not what it should do |
| Error handling that catches and logs but doesn't recover | Looks like error handling exists; actually, errors are just silenced |
| Comments explaining "why" that restate the "what" | `// increment counter` above `counter++` is not documentation |
| Security measures on the obvious attack vector but not the subtle ones | SQL injection prevented but IDOR vulnerability left open |
| "This handles edge cases" followed by one null check | One edge case handled does not mean edge cases are handled |

### Signs of Genuine Thoroughness

| Signal | What It Indicates |
|--------|-------------------|
| Different behavior for different failure modes (not one generic catch) | The failure taxonomy was actually considered |
| Test cases that include boundary values, not just happy path | Testing strategy reflects real-world input distribution |
| Explicit statements about what is NOT handled and why | Honest about scope rather than pretending completeness |
| Questions back to the user about ambiguous requirements | Resistance to assumption indicates real analysis |
| Architectural consistency with the existing codebase | Context was actually loaded and followed, not ignored |
| Rollback or compensation logic for multi-step operations | Failure recovery was designed, not just acknowledged |

### Verification Techniques

1. **Ask for the failure mode.** "What happens if this fails at step 3?" If the AI gives a vague answer, it hasn't thought about it.
2. **Ask for what was left out.** "What does this implementation NOT handle?" A genuinely thorough implementation has a clear, honest answer. A performed-thorough one says "it handles all the key cases."
3. **Check test assertions.** Are they testing behavior or testing implementation? Do they cover invalid input, boundary conditions, and error cases — or just the success path?
4. **Look at error handling.** Count the distinct error types and compare to the number of things that can go wrong. If there's one `catch` block for five possible failures, error handling is decorative.
5. **Verify library usage.** Pick one non-trivial library call and check the actual documentation. Does the function exist? Do the parameters exist? Does it behave as the code assumes?

### The Meta-Question

"If I deleted all the comments, renamed all the variables to single letters, and just read the logic — does this code actually handle the hard cases? Or does it only look like it does because the comments and names suggest thoroughness?"

---

## Summary Table

| Blind Spot | Core Failure | Detection Question |
|-----------|-------------|-------------------|
| Happy path bias | Only success case implemented | "What happens when this fails at each step?" |
| Scope acceptance | Requirements not questioned | "Did the AI push back on anything?" |
| Confidence without correctness | Wrong code presented confidently | "Is this provably correct or just plausible?" |
| Test rewriting | Tests changed to match bugs | "Was the test or the code wrong?" |
| Pattern attraction | Over-engineered common patterns | "Is this the simplest solution?" |
| Reactive patching | Workarounds instead of redesign | "Would we build it this way from scratch?" |
| Context rot | Quality degrades over long sessions | "Is this consistent with earlier decisions?" |
| Library hallucination | Non-existent APIs referenced | "Does this function/parameter actually exist?" |
| Architectural inconsistency | Local optimization, global incoherence | "Does this match patterns in the rest of the codebase?" |
| XY problem blindness | Solves stated request, not real problem | "What's the actual problem behind this request?" |
| Over-abstraction | Premature generalization | "Which abstractions serve current requirements?" |
| Security as afterthought | Functionality first, security optional | "Can user A affect user B's data?" |
