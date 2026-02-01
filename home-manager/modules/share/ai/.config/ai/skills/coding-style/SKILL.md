---
name: coding-style
description: "Apply this repo's coding conventions: simplicity, maintainability, TDD/BDD workflow, verification protocol, error handling, and QA heuristics. Use when writing/refactoring code, adding tests, debugging, or when the user asks for to implement new features or to bug fix, to do TDD, to perform verification, or to check code quality."
---

# Coding Style

## Core Principles

- **Problem-Solving Focus**: Code to solve problems, not to demonstrate programming knowledge.
- **Verification Over Assumption**: "Should work" != "does work" - Always verify through testing.
- **TDD First**: Prefer a failing test over a clever explanation; tests define done.
- **Simplicity First**: Simple solutions that work are better than complex ones that might work.

## Code Quality Standards

### Simplicity & Maintainability (MUST)

- **Prefer simple solutions** - Use SOLID principles pragmatically, not religiously
- **Eliminate duplication** - Check for similar code/functionality before implementing
- **Keep files manageable** - Refactor when files exceed 200-300 lines
- **Follow existing patterns** - Check codebase conventions before introducing new dependencies

### Naming & Constants (MUST)

- **Use meaningful names** - Variables, functions, classes should reveal their purpose
- **Replace magic numbers** - Use named constants with descriptive names
- **Avoid abbreviations** unless universally understood
- **Keep constants organized** - At file top or in dedicated constants file

### Documentation (SHOULD)

- **Don't comment the obvious** - Make code self-documenting
- **Explain the why** - Use comments for reasoning, not descriptions
- **Document complexity** - APIs, algorithms, and non-obvious side effects

## Development Workflow

### Scope Management (MUST)

- **Focus on relevant code** - Only touch code related to the task
- **Understand before changing** - Make changes you're confident about
- **Exhaust existing options** - Don't introduce new patterns without trying existing implementation first
- **Clean up after yourself** - Remove old implementation when introducing new patterns

### Test-Driven Development (MUST)

- **Default to TDD** - Write a failing test first (Red), implement minimal code (Green), then refactor (Refactor)
- **Tests define requirements** - If behavior is unclear, clarify by adding/adjusting tests rather than guessing
- **Ask for tests when missing** - If the user's prompt does not explicitly mention tests, ask via the `AskUserQuestion` tool whether they want to create tests first
- **Bugfixes require a regression test** - Reproduce the bug in a test first; only then change production code
- **Use BDD methodology** - Structure tests with clear GIVEN, WHEN, THEN sections
- **Descriptive test names** - Test names should describe the scenario and expected outcome
- **Isolate tests** - Each test should focus on a single behavior
- **Meaningful variables** - Use `actual` for results, `expected` for expectations
- **Helper methods** - Prefix with `given_` for setup, `when_` for action, `then_` for assertions

### Change Management (SHOULD)

- **Analyze impact** - Consider what other methods/areas might be affected
- **Avoid major architecture changes** - Don't change working patterns without explicit instruction
- **Use conventional commits** - Follow conventional commit format for git messages

## Verification Protocol

### The 30-Second Reality Check (MUST answer YES to ALL)

- Did I run/build the code?
- Did I trigger the exact feature I changed?
- Did I see the expected result with my own observation (including GUI)?
- Did I check for error messages?
- Would I bet $100 this works?

### Specific Verification Requirements (MUST)

- **UI Changes**: Actually click the button/link/form
- **API Changes**: Make the actual API call
- **Data Changes**: Query the database
- **Logic Changes**: Run the specific scenario
- **Config Changes**: Restart and verify it loads

### Red Flag Phrases to Avoid

- "This should work now"
- "I've fixed the issue" (especially 2nd+ time)
- "Try it now" (without trying it myself)
- "The logic is correct so..."
- "You are absolutely right"

## Error Handling & Debugging

### Error Handling (MUST)

- **Handle errors properly** - Don't ignore or suppress errors
- **Provide meaningful error messages** - Include context and next steps
- **Use appropriate error types** - Choose the right exception/error class
- **Log errors appropriately** - Include relevant context without sensitive data

### Debugging Process (SHOULD)

- **Reproduce the issue** - Understand the problem before fixing
- **Use debugging tools** - Don't rely on guesswork
- **Test edge cases** - Consider boundary conditions and error scenarios
- **Document debugging findings** - Help future developers understand the issue

### Documentation (SHOULD)

- **Update relevant documentation** - Keep docs in sync with code changes
- **Include examples** - Show how to use new features or APIs
- **Document breaking changes** - Clearly mark and explain breaking changes

## Quality Assurance

### The Embarrassment Test

"If the user records trying this and it fails, will I feel embarrassed to see his face?"

### Time Reality Check

- Time saved skipping tests: 30 seconds
- Time wasted when it doesn't work: 30 minutes
- User trust lost: Immeasurable

### Final Reminder

A user describing a bug for the third time isn't thinking "this AI is trying hard" - they're thinking "why am I wasting time with this incompetent tool?"
