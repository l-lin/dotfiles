**Purpose**: Git commit

---

<instructions>

## Objective

Generate semantic git commit messages that include ticket IDs extracted from branch names and document the full conversation context.

## Requirements

### 1. Ticket ID Extraction

Extract the ticket ID from the git branch name and include it in the commit scope.

<example>
Examples of getting the ticket id from the branch name:

- P3C-123/do_some_stuff => P3C-123
- P3C-123-do_some_stuff => P3C-123
- P3C-123_do_some_stuff => P3C-123
- feat/P3C-123/do_some_stuff => P3C-123
- feature/ABC-456-user-auth => ABC-456
- bugfix/DEF-789_fix_login => DEF-789
  </example>

### 2. Commit Message Format

Use conventional commit format: `type(scope): description`

- **type**: feat, fix, docs, style, refactor, test, chore, etc.
- **scope**: The extracted ticket ID
- **description**: Brief summary of changes (max 50 chars for first line)

### 3. Conversation Documentation

Include the complete user prompt in the commit message body within triple backticks.

- Copy the user's prompt verbatim
- Summarize AI responses in less than 200 characters per interaction
- Maintain conversation flow and context

### 4. Workflow

1. Generate the commit message following the format above
2. Ask the user to validate or update the message
3. Stage the diffs and commit them with the approved message

### 5. Best Practices

- Keep the subject line under 50 characters
- Use imperative mood ("add" not "added" or "adds")
- Capitalize the first letter of the description
- No period at the end of the subject line
- Include breaking changes if applicable

</instructions>

<example>
feat(P3C-123): Add user authentication with JWT tokens

```
👤 Please implement user authentication using JWT tokens. The system should:
1. Allow users to login with email/password
2. Generate JWT tokens on successful authentication
3. Validate tokens on protected routes
4. Include refresh token mechanism
5. Handle token expiration gracefully

Make sure to follow security best practices and add proper error handling.

🤖 Response Summary:
Implemented JWT auth system with login endpoint, token validation middleware, refresh mechanism, and security measures. Added bcrypt password hashing, token expiration handling, and comprehensive error responses.

Changes:
- Created auth middleware for token validation
- Added login/refresh endpoints with proper validation
- Implemented secure password hashing with bcrypt
- Added JWT token generation and verification
- Created protected route examples
- Added error handling for expired/invalid tokens
```
</example>
