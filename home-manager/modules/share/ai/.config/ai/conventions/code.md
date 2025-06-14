# Coding Convention

<coding_patterns>
## Coding Pattern Preferences

<simplicity>
- Always prefer simple solution
  - Use SOLID principles whenever possible, but do not religiously follow them
- Avoid duplication of code whenever possible, which means checking for other areas of the codebase that might already have similar code and functionality
</simplicity>

<change_management>
- You are careful to only make changes that are requested or you are confident you understood well to the topics related to the change being requested
- When fixing an issue or bug, do not introduce a new pattern or technology without first exhausting all options for the existing implementation
  - And if you finally do this, make sure to remove the old implementation afterwards so we don't have duplicate logic
</change_management>

<code_organization>
- Keep the codebase very clean and organized
- Avoid writing scripts in files if possible, especially if the script is likely only to be run once
- Avoid having files over 200-300 lines of code. Refactor at that point
</code_organization>

<constants_and_naming>
### Constants Over Magic Numbers
- Replace hard-coded values with named constants
- Use descriptive constant names that explain the value's purpose
- Keep constants at the top of the file or in a dedicated constants file

### Meaningful Names
- Variables, functions, and classes should reveal their purpose
- Names should explain why something exists and how it's used
- Avoid abbreviations unless they're universally understood
</constants_and_naming>

<documentation>
### Smart Comments
- Don't comment on what the code does - make the code self-documenting
- Use comments to explain why something is done a certain way
- Document APIs, complex algorithms, and non-obvious side effects
</documentation>
</coding_patterns>

<workflow_preferences>
## Coding Workflow Preferences

<scope_management>
- Focus on the areas of code relevant to the task
- Do not touch code that is unrelated to the task
</scope_management>

<development_methodology>
- Follow Test-Driven Development (TDD) principles, i.e. start with the test and then implement the code
- Avoid making major changes to the patterns and architecture of how a feature works, after it has shown to work well, unless explicitly instructed
</development_methodology>

<impact_analysis>
- Always think about what other methods and areas of code might be affected by code changes
- After each code change, commit the changes following conventional commit for the git message
</impact_analysis>
</workflow_preferences>

<testing_conventions>
## Testing Convention

<testing_methodology>
- Behavior-Driven Development (BDD) testing methodology
- Clean code and test design principles
- Structure each test with clear GIVEN, WHEN, THEN sections
- Use descriptive test method names that reflect the scenario
- Implement test setup with meaningful variable names
- Ensure tests are isolated and focused on a single behavior
- If some files are needed to implement the test, ask the user to include them in the context
</testing_methodology>

<test_format>
### Tests Output Format

- Clear section comments (// GIVEN, // WHEN, // THEN)
- Create test methods using the BDD pattern
- Descriptive method and variable names
- Use `actual` as variable name if the tested method returns something
- Use `expected` as variable name for the expected output
- Helper methods prefixed with `given_` for test setup and `then_` for test assertions where appropriate
</test_format>
</testing_conventions>

