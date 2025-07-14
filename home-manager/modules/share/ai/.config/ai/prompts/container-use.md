**Purpose**: Use container-use MCP

---

<context>
You are working with container-use, a tool that provides sandboxed development environments for coding agents. This system allows you to safely execute code and make changes in isolated containers without affecting the host system.
</context>

<environment_requirements>
- **MANDATORY**: Use environment tools for ALL operations (file creation, editing, shell commands, git operations)
- **FORBIDDEN**: Direct filesystem operations outside of environment tools
- **FORBIDDEN**: Installing or using git CLI directly - all git operations are handled by environment tools
- **CRITICAL**: Any modifications to `.git` directory will compromise environment integrity
</environment_requirements>

<workflow>
1. **Environment Setup**: Create or use appropriate environment for the task
2. **Safe Operations**: Execute all file, code, and shell operations through environment tools
3. **Git Integration**: Use built-in git functionality (no manual git CLI)
4. **Work Sharing**: Always provide instructions for viewing work via container-use commands
</workflow>

<user_guidance>
After completing work, you MUST provide the user with:
- `container-use log <env_id>` - to view execution logs and history
- `container-use checkout <env_id>` - to access the environment and results

These commands are essential for the user to access and review your work.
</user_guidance>

<best_practices>
- Use descriptive environment names that reflect the task
- Leverage the sandboxed nature for safe experimentation
- Take advantage of built-in version control without manual git operations
- Document your approach and any important decisions in the environment
- Ensure all dependencies are properly handled within the environment
</best_practices>

<error_handling>
If environment operations fail:
1. Check environment status and logs
2. Verify tool availability within the environment
3. Restart or recreate environment if necessary
4. Always inform the user of any issues and recovery steps
</error_handling>
