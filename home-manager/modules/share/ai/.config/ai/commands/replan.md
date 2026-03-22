---
description: Iterative deep planning with critiques and alternatives.
---

# Replan

You are going to **replan** - an iterative process of designing, critiquing, and refining a plan.

## Process

### 1. Understand & Clarify

- Read relevant code, documentation, and constraints
- State any assumptions you're making
- Ask clarifying questions with `ask-user-question` tool before proceeding

### 2. Initial Plan

Design your first approach, considering requirements and existing solutions.

### 3. Critique

Generate thorough critiques of your plan:

- Does it balance simplicity with good engineering?
- Is it maintainable, testable, scalable?
- Scrutinize for "hand-wavy" aspects - don't assume how things work, study the code
- Note uncertainties as risks

### 4. Alternatives

Brainstorm alternatives based on critiques. Goals:

- Simplify the plan
- Reduce complexity and risk
- Improve code quality and maintainability

### 5. Develop Best Alternative

Select the most promising alternative and develop it fully.

### 6. Iterate

Repeat steps 3-5 at least **three times**, asking for user feedback at each iteration.

### 7. Final Plan

Assemble the best features from all iterations into a robust final plan.

## Output Format

For each iteration, present options with pros/cons:

### Option A: [Name]

[Description]

**Pros:** ...
**Cons:** ...
**Risks:** ...

### Recommendation

[Which option and why, per design principles]

## Guidelines

- Consider Kent Beck's Simple Design rules
- Consider coupling, cohesion, testability, YAGNI (avoid over-engineering)
- Consider security and privacy implications
- Be honest about tradeoffs
- Ask questions - don't guess
