---
name: self-review
description: Perform a critical self-review of recently written code to catch bugs, edge cases, and quality issues before delivery. Use when user says "review your code", "check your work", "self-review", "fresh eyes", or after completing significant code changes.
---

# Self-Review Protocol

## Purpose

After writing or modifying code, perform a thorough self-inspection to catch issues that are easy to miss during initial implementation.

## Review Iterations

- **Default**: Perform 3 independent review passes
- **User-specified**: If user says "review N times", use that number
- Each pass should approach the code with fresh perspective
- Continue until all passes find no issues OR max iterations reached

## Trigger Conditions

- User explicitly requests review ("review your code", "check that", "self-review")
- After completing substantial code changes (optional, use judgment)
- Before marking a task as complete

## Review Checklist

Examine ALL code written or modified in this session. Look for:

1. **Correctness**
   - Obvious bugs, logical errors, or typos
   - Off-by-one errors, null checks, boundary conditions
   - Incorrect operators or comparison logic

2. **Edge Cases**
   - Empty inputs, null values, undefined states
   - Boundary values (min/max, zero, negative)
   - Concurrent access issues
   - Resource exhaustion scenarios

3. **Error Handling**
   - Missing try/catch blocks
   - Unhandled promise rejections
   - Silent failures
   - Poor error messages

4. **Code Quality**
   - Dead code or unused parameters
   - Unnecessary complexity or duplication
   - Variables used before initialization
   - Type mismatches or unsafe casts
   - Resource leaks (file handles, connections)

5. **Consistency**
   - Naming conventions
   - Code style alignment with project
   - Missing documentation for complex logic

## Response Format

**After each review pass:**

**If issues found:**

1. Fix them immediately
2. Report: "Pass [X/N]: Fixed [M] issue(s)."
3. List what was fixed (brief)
4. Continue to next pass

**If no issues found in current pass:**

1. Report: "Pass [X/N]: No issues found."
2. List what was verified (brief)
3. Continue to next pass

**After all passes complete:**

- Report total: "Completed [N] passes. Total fixes: [M]. Review complete."

## Rules

- **Think deeply**: Don't rush to a verdict
- **Be skeptical**: Assume there might be issues
- **Be thorough**: Check every function, every branch
- **Be honest**: Report issues even if embarrassing
- **No defensiveness**: If you find a bug, just fix it
- **Independent passes**: Each review pass should use a different mental model or focus area
- **No shortcuts**: Complete all N passes even if early passes find nothing

## Example Multi-Pass Response

```
Pass 1/3: Fixed 2 issue(s).
1. Added null check in `parseInput()` - crashed on empty string
2. Fixed off-by-one in loop boundary - skipped last element

Pass 2/3: Fixed 1 issue(s).
1. Removed unused parameter `options` in `validate()`

Pass 3/3: No issues found.
Verified:
- All 4 functions handle null/undefined inputs
- Error paths tested with edge cases (empty, zero, negative)
- No unused variables or dead code
- Resource cleanup in finally blocks
- Type safety maintained throughout

Completed 3 passes. Total fixes: 3. Review complete.
```
