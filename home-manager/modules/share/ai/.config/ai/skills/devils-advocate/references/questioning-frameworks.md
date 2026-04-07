# Questioning Frameworks

Reference material for structured critical analysis of software decisions, code, plans, and architecture.

---

## 1. Pre-Mortem Analysis (Gary Klein)

### What It Is

A pre-mortem assumes the project/decision has already failed and works backward to identify causes. Unlike a post-mortem (which happens after failure), a pre-mortem leverages prospective hindsight — the psychological finding that people are 30% better at identifying reasons for an outcome when they imagine it has already occurred.

### When to Use

- Before shipping a feature, migration, or architectural change
- Before committing to a technical direction that's hard to reverse
- When reviewing a plan that "feels right" but hasn't been stress-tested
- Before any deployment with data migration or schema changes

### Step-by-Step Process

1. **Frame the failure.** State: "It is six months from now. This [feature/migration/decision] shipped and caused a serious incident. The team is in an emergency war room."
2. **Generate failure stories independently.** Each participant (or each pass of analysis) writes specific failure scenarios — not vague risks, but narratives: "The migration ran for 47 minutes, exceeded the maintenance window, and left the database in an inconsistent state because..."
3. **Identify the most plausible failures.** Rank by likelihood x impact. Focus on failures that are both plausible and would be embarrassing in retrospect ("we should have seen that coming").
4. **Trace each failure to its root cause in the current plan.** What assumption, missing test, or unhandled case would have caused this?
5. **Determine preventive actions.** For each plausible failure: what would you add, change, or test to prevent it?

### Example Questions for Software Context

| Scenario | Pre-Mortem Question |
|----------|-------------------|
| New API endpoint | "This endpoint caused a production outage. The on-call engineer's pager went off at 3am. What happened?" |
| Database migration | "The migration failed halfway through on production. What was different about prod that we didn't account for?" |
| Feature launch | "Users are furious. Support tickets tripled. What did we get wrong about how they'd actually use this?" |
| Dependency upgrade | "The upgrade broke production silently — no errors, just wrong behavior. What changed that our tests didn't cover?" |
| Performance optimization | "The optimization made things worse under real load. What about production traffic patterns did we miss?" |

### Key Insight

The power of pre-mortem is that it gives people permission to voice concerns they'd otherwise suppress. In code review, this translates to: "I'm not saying this is wrong, I'm saying IF it failed, here's how it would fail."

---

## 2. Inversion (Charlie Munger)

### What It Is

Instead of asking "how do we succeed?", ask "what would guarantee failure?" then ensure none of those conditions exist. Munger's principle: "Invert, always invert." Many problems are easier to solve backward than forward.

### When to Use

- Evaluating whether a design is robust
- Reviewing acceptance criteria — are they sufficient?
- Assessing operational readiness
- When a plan seems solid but you can't articulate specific concerns

### Three-Step Process

1. **Define the opposite goal.** If the goal is "reliable data processing pipeline," the inverse is "guaranteed data loss or corruption."
2. **Enumerate ways to achieve the inverse.** Be thorough and specific:
   - "Never validate input schemas"
   - "Ignore partial failures and continue processing"
   - "No idempotency keys on writes"
   - "Deploy without rollback capability"
   - "No monitoring on queue depth or processing lag"
3. **Check the current plan against each item.** For every failure-guaranteeing condition, verify the plan actively prevents it. Any gap is a finding.

### Example Applications

**Inversion applied to authentication system:**

| "To guarantee a security breach, we would..." | Check |
|-----------------------------------------------|-------|
| Store passwords in plaintext | Bcrypt/argon2 with salt? |
| Never expire sessions | Token TTL + refresh rotation? |
| Return different errors for "user not found" vs "wrong password" | Uniform error messages? |
| Allow unlimited login attempts | Rate limiting + lockout? |
| Send tokens in URL query parameters | Headers only, no logging? |
| Trust client-side role claims | Server-side authorization on every request? |

**Inversion applied to deployment:**

| "To guarantee a failed deployment, we would..." | Check |
|--------------------------------------------------|-------|
| Deploy on Friday at 5pm with no rollback plan | Deployment windows + rollback runbook? |
| Run migrations that can't be reversed | Backward-compatible migrations? |
| Skip canary/staged rollout | Progressive deployment? |
| Have no way to verify success post-deploy | Health checks + smoke tests? |
| Depend on manual steps that aren't documented | Automated pipeline? |

### Example Questions

- "If we wanted to guarantee data corruption in this pipeline, what would we do? Now — are any of those conditions present?"
- "What's the fastest way a malicious insider could exploit this? Do we prevent it?"
- "If we wanted users to abandon this feature in frustration, what would the UX look like? Does ours resemble that?"
- "What would make this system impossible to debug in production?"

---

## 3. Socratic Questioning (Six Types)

### What It Is

Socratic questioning is a disciplined method of probing thinking through six categories of questions. It doesn't assert — it reveals gaps, assumptions, and contradictions by asking the right questions in sequence.

### When to Use

- During code review or design review
- When evaluating a technical proposal
- When someone (including yourself) is confident in an approach
- To help surface implicit assumptions

### The Six Types

#### 3.1 Clarification Questions

**Purpose:** Ensure the claim or decision is well-defined. Vague statements hide complexity.

| Question | When to Use |
|----------|-------------|
| "What exactly do you mean by [term]?" | When jargon or ambiguous terms are used ("scalable," "robust," "simple") |
| "Can you give a concrete example of how this would work?" | When the description is abstract |
| "What's the specific user action that triggers this code path?" | When reviewing business logic |
| "What does 'done' look like for this? What's the acceptance test?" | When scope is unclear |
| "When you say 'handle errors gracefully,' what does the user see?" | When error handling is described but not specified |

#### 3.2 Probing Assumptions

**Purpose:** Surface and test beliefs taken for granted. Most design flaws stem from untested assumptions.

| Question | When to Use |
|----------|-------------|
| "What are we assuming about the input data that might not hold?" | Data processing, API endpoints |
| "Are we assuming this third-party service will always be available?" | Integration points |
| "What if the user doesn't follow the expected flow?" | UI/UX decisions |
| "Are we assuming the data fits in memory?" | Processing pipelines |
| "What if this table grows 100x? Does the query plan still work?" | Database design |
| "Are we assuming deploys happen with zero in-flight requests?" | Migration/deployment plans |
| "Is there an assumption here about ordering or timing?" | Distributed systems, event processing |

#### 3.3 Probing Evidence / Reasoning

**Purpose:** Examine the basis for a claim. "How do we know this is true?"

| Question | When to Use |
|----------|-------------|
| "What data supports this design choice?" | When a choice is presented as obvious |
| "Has this pattern been tested under production-like conditions?" | Performance claims |
| "Where did the requirement for [X] come from? Can we verify it?" | When building to assumed requirements |
| "What's the evidence that users actually need this?" | Feature decisions |
| "How do we know the current implementation is actually the bottleneck?" | Optimization efforts |

#### 3.4 Questioning Perspectives / Viewpoints

**Purpose:** Consider alternative angles. What would someone with a different role, context, or expertise think?

| Question | When to Use |
|----------|-------------|
| "How would the on-call engineer experience this at 3am?" | Operational readiness |
| "What would a new team member think when reading this code?" | Code clarity |
| "How does this look from the attacker's perspective?" | Security review |
| "What would the DBA say about this query pattern?" | Database usage |
| "If we inherited this codebase, what would frustrate us?" | Code quality |
| "What would the customer support team need when this breaks?" | Error handling, observability |

#### 3.5 Probing Implications / Consequences

**Purpose:** Follow the decision to its logical conclusion. What happens next? And after that?

| Question | When to Use |
|----------|-------------|
| "If we do this, what does that commit us to maintaining?" | Architectural decisions |
| "What's the migration path if this approach doesn't scale?" | Technology choices |
| "If this succeeds wildly, what breaks first?" | Capacity planning |
| "What becomes harder to change after we ship this?" | Reversibility assessment |
| "What other teams or systems are affected by this change?" | Blast radius |
| "If we add this column now, what does the migration look like in 2 years?" | Schema design |

#### 3.6 Meta-Questions (Questions About the Question)

**Purpose:** Examine the framing itself. Are we solving the right problem?

| Question | When to Use |
|----------|-------------|
| "Why is this the question we're asking? Is there a better framing?" | When stuck or going in circles |
| "Are we solving the symptom or the root cause?" | Bug fixes, workarounds |
| "Is this actually our problem to solve, or should it be handled elsewhere?" | Scope/boundary decisions |
| "What would we do if we couldn't use this approach at all?" | When fixated on one solution |
| "Are we optimizing for the right metric?" | Performance/business decisions |

---

## 4. Steel-Manning

### What It Is

Before criticizing a decision or approach, articulate the strongest possible version of why it's reasonable. This is the opposite of a straw man — you construct the best case FOR the approach, then evaluate whether your critique still holds.

### Why It Matters for Calibration

- Prevents knee-jerk "that's wrong" reactions that miss context
- Forces you to understand the tradeoffs the author actually considered
- Makes your eventual critique more credible and specific
- Catches cases where the approach is actually correct and you're the one missing something

### When to Use

- Before every critique — this should be the default first step
- When your instinct is "this is wrong" — that instinct is often right, but the steel-man ensures the critique is precise
- When reviewing code from someone with more domain context than you

### Step-by-Step Process

1. **Identify the decision.** What specific choice was made? (Not a vague "this is bad" — name the exact decision.)
2. **List the constraints the author faced.** Time pressure, backward compatibility, team expertise, existing patterns, business requirements.
3. **Construct the best argument FOR this approach.** "This approach is reasonable because..."
4. **Identify what would need to be true for this approach to be optimal.** "This is the right call IF..."
5. **Now evaluate:** Are those conditions actually true? If not, what specifically changes?

### Example

**Decision:** A team chose to use polling instead of WebSockets for real-time updates.

| Step | Analysis |
|------|----------|
| Steel-man | "Polling is simpler to implement, debug, and deploy. It works through all proxies and load balancers without special configuration. The team has no WebSocket experience, and the update frequency (every 30s) doesn't require true real-time. The operational cost of maintaining WebSocket connections at scale is non-trivial." |
| Conditions | "This is optimal IF update latency of 30s is acceptable, IF the polling load is manageable at expected scale, IF there's no future requirement for sub-second updates." |
| Evaluation | "The business requirement says 'near real-time' which the PM defined as <5s. 30s polling doesn't meet this. Additionally, at projected user count, polling creates 200 req/s that WebSockets would eliminate. The steel-man is strong on operational simplicity but breaks on the latency requirement." |

### Example Questions

- "What's the strongest argument for keeping this exactly as it is?"
- "Under what conditions would this be the ideal approach?"
- "What constraints made this the pragmatic choice?"
- "If I had to defend this approach in a design review, what would I say?"
- "What am I missing about the context that would make this reasonable?"

---

## 5. Six Thinking Hats (Edward de Bono)

### What It Is

A method for examining a decision from six distinct perspectives, one at a time. The value is in deliberate perspective-switching — most people default to one or two modes and ignore the rest.

### When to Use

- When a decision has been made quickly and feels "obvious"
- When a group is stuck in one mode of thinking (e.g., only discussing risks, or only discussing benefits)
- For structured review of an architectural decision record (ADR)

### The Four Most Relevant Hats for Software Review

#### Black Hat — Risks and Problems

The devil's advocate hat. What can go wrong?

**Process:** Assume this will fail. Enumerate every failure mode, risk, and weakness.

| Question | Focus |
|----------|-------|
| "What's the worst case if this fails?" | Impact assessment |
| "Where is the single point of failure?" | Resilience |
| "What happens when the dependency is down?" | Fault tolerance |
| "What's the security attack surface?" | Security |
| "Where will this be painful to maintain in a year?" | Technical debt |

#### White Hat — Missing Data

What do we know? What don't we know? What do we need to find out?

**Process:** Strip away opinions and assumptions. Focus only on facts, data, and gaps.

| Question | Focus |
|----------|-------|
| "What's the actual measured latency, not the expected?" | Real vs. assumed performance |
| "How many users will actually hit this code path?" | Usage data |
| "Do we have production data on error rates for this integration?" | Empirical evidence |
| "What don't we know about the customer's usage pattern?" | Unknown unknowns |
| "Have we load-tested this, or are we estimating?" | Data quality |

#### Green Hat — Alternatives

Creative exploration. What else could we do?

**Process:** Generate options without judging them. Quantity over quality in this phase.

| Question | Focus |
|----------|-------|
| "What if we didn't build this at all? What's the manual workaround?" | Necessity check |
| "What's a completely different architecture that solves this?" | Fresh perspective |
| "What would [company known for this] do?" | Pattern borrowing |
| "What if we split this into two simpler problems?" | Decomposition |
| "What's the simplest version that would still be useful?" | MVP thinking |

#### Blue Hat — Meta/Process

Thinking about the thinking. Are we asking the right questions?

**Process:** Step back from the content. Evaluate the quality of the analysis itself.

| Question | Focus |
|----------|-------|
| "Have we talked to the people who'll actually use/maintain this?" | Stakeholder coverage |
| "Are we spending time on the highest-risk areas?" | Prioritization |
| "What decision are we actually making right now?" | Scope clarity |
| "Do we have the right people in this discussion?" | Expertise coverage |
| "What's our decision criteria? How will we know which option is better?" | Framework |

### How to Apply Sequentially

When reviewing a decision or plan:

1. **Blue** (2 min): What are we evaluating? What matters most?
2. **White** (5 min): What do we actually know? What data is missing?
3. **Green** (5 min): What alternatives exist? (List without judging.)
4. **Black** (10 min): What can go wrong with the proposed approach?
5. **Steel-man** (3 min): What's the strongest case FOR this approach?
6. **Blue** (2 min): Given all of this, what's our recommendation?

---

## 6. Five Whys (Reverse Application)

### What It Is

The classic Five Whys traces from a problem backward to its root cause. In reverse application for decision review, you trace from a decision backward to its underlying motivation — exposing whether the stated rationale actually supports the choice.

### When to Use

- When reviewing a design decision that feels like it was made by convention
- When the rationale is "this is how we've always done it" or "this is best practice"
- When a technical choice seems disconnected from the actual problem

### Step-by-Step Process

Start with the decision and ask "why was this approach chosen?" repeatedly:

1. **Why this approach?** (Surface rationale)
2. **Why does that matter?** (Underlying concern)
3. **Why is that the constraint?** (Real constraint vs. assumed)
4. **Why can't that constraint be changed?** (Fixed vs. movable)
5. **Why is this the best way to address that root concern?** (Alternatives)

### Example: "We chose a microservices architecture"

| Level | Question | Answer |
|-------|----------|--------|
| Why 1 | "Why microservices?" | "We need independent deployability." |
| Why 2 | "Why do you need independent deployability?" | "Different features have different release cadences." |
| Why 3 | "Why do features have different release cadences?" | "The payments team ships weekly, the search team ships daily." |
| Why 4 | "Why can't they ship on the same cadence?" | "Payments requires compliance review before each release." |
| Why 5 | "Is there a simpler way to gate payments releases without splitting the entire architecture?" | "...actually, a feature flag + approval gate on the CI pipeline might work." |

### Example: "We're using Redis for caching"

| Level | Question | Answer |
|-------|----------|--------|
| Why 1 | "Why Redis?" | "We need caching for performance." |
| Why 2 | "Why is performance a problem?" | "The dashboard loads slowly." |
| Why 3 | "Why does the dashboard load slowly?" | "It makes 12 API calls on mount." |
| Why 4 | "Why 12 API calls?" | "Each widget fetches its own data independently." |
| Why 5 | "Could a single aggregated endpoint eliminate the need for caching?" | "...that would solve the latency without adding infrastructure." |

### Example Questions for General Use

- "Why was this library/framework/tool chosen over alternatives?"
- "Why is this a hard requirement vs. a preference?"
- "Why can't the upstream system provide this data in the format we need?"
- "Why is this our responsibility rather than the caller's?"
- "Why do we need this abstraction layer?"

### Key Insight

Reverse Five Whys frequently reveals that a complex solution is addressing a symptom rather than the root problem. The fifth "why" often points to a simpler intervention at a different level.

---

## Framework Selection Guide

| Situation | Primary Framework | Supporting Framework |
|-----------|------------------|---------------------|
| Reviewing a plan before execution | Pre-Mortem | Inversion |
| Evaluating a specific technical decision | Five Whys (Reverse) | Steel-Manning |
| Comprehensive design review | Six Thinking Hats | Socratic (all types) |
| "This feels wrong but I can't say why" | Inversion | Pre-Mortem |
| Challenging a confident proposal | Steel-Manning first | Then Socratic Assumptions |
| Exploring whether we're solving the right problem | Socratic Meta-Questions | Five Whys (Reverse) |
| Assessing operational readiness | Pre-Mortem | Inversion |
| Reviewing someone else's code/PR | Steel-Manning first | Socratic Clarification |

---

## Combining Frameworks: Recommended Sequence

For a thorough review of any significant decision:

1. **Steel-Man** — Understand why this approach is reasonable
2. **Socratic Clarification** — Ensure the decision is well-defined
3. **Five Whys (Reverse)** — Trace to root motivation
4. **Inversion** — Enumerate failure conditions
5. **Pre-Mortem** — Narrate specific failure scenarios
6. **Socratic Implications** — Follow consequences forward

This sequence moves from understanding to challenging — it builds credibility before critique, which makes the critique more effective and more likely to surface real issues rather than stylistic preferences.
