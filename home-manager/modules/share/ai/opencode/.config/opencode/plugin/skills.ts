import path from "path";
import fs from "fs";
import os from "os";
import type { Plugin, PluginInput } from "@opencode-ai/plugin";
import { tool } from "@opencode-ai/plugin";

interface Frontmatter {
  name: string;
  description: string;
}

interface SkillInfo {
  path: string;
  skillFile: string;
  name: string;
  description: string;
  sourceType: string;
}

interface ResolvedSkill {
  skillFile: string;
  skillPath: string;
  sourceType?: string;
}

interface ToolContext {
  sessionID: string;
}

/**
 * Extract YAML frontmatter from a skill file.
 * Current format:
 * ---
 * name: skill-name
 * description: Use when [condition] - [what it does]
 * ---
 *
 * @param filePath - Path to SKILL.md file
 * @returns Object containing name and description
 */
function extractFrontmatter(filePath: string): Frontmatter {
  try {
    const content = fs.readFileSync(filePath, "utf8");
    const lines = content.split("\n");

    let inFrontmatter = false;
    let name = "";
    let description = "";

    for (const line of lines) {
      if (line.trim() === "---") {
        if (inFrontmatter) break;
        inFrontmatter = true;
        continue;
      }

      if (inFrontmatter) {
        const match = line.match(/^(\w+):\s*(.*)$/);
        if (match) {
          const [, key, value] = match;
          switch (key) {
            case "name":
              name = value.trim();
              break;
            case "description":
              description = value.trim();
              break;
          }
        }
      }
    }

    return { name, description };
  } catch (error) {
    return { name: "", description: "" };
  }
}

/**
 * Find all SKILL.md files in a directory recursively.
 *
 * @param dir - Directory to search
 * @param sourceType - 'personal' or 'project' for namespacing
 * @param maxDepth - Maximum recursion depth (default: 3)
 * @returns Array of skill information objects
 */
function findSkillsInDir(dir: string, sourceType: string, maxDepth: number = 3): SkillInfo[] {
  const skills: SkillInfo[] = [];

  if (!fs.existsSync(dir)) return skills;

  function recurse(currentDir: string, depth: number): void {
    if (depth > maxDepth) return;

    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        // Check for SKILL.md in this directory
        const skillFile = path.join(fullPath, "SKILL.md");
        if (fs.existsSync(skillFile)) {
          const { name, description } = extractFrontmatter(skillFile);
          skills.push({
            path: fullPath,
            skillFile: skillFile,
            name: name || entry.name,
            description: description || "",
            sourceType: sourceType,
          });
        }

        // Recurse into subdirectories
        recurse(fullPath, depth + 1);
      }
    }
  }

  recurse(dir, 0);
  return skills;
}

/**
 * Resolve a skill name to its file path, handling shadowing
 * (personal skills override superpowers skills).
 *
 * @param skillName - Name like "my-skill"
 * @param personalDir - Path to personal skills directory
 * @returns Resolved skill info or null
 */
function resolveSkillPath(skillName: string, personalDir: string): ResolvedSkill | null {
  const personalPath = path.join(personalDir, skillName);
  const personalSkillFile = path.join(personalPath, "SKILL.md");
  if (fs.existsSync(personalSkillFile)) {
    return {
      skillFile: personalSkillFile,
      skillPath: skillName,
    };
  }

  return null;
}

/**
 * Strip YAML frontmatter from skill content, returning just the content.
 *
 * @param content - Full content including frontmatter
 * @returns Content without frontmatter
 */
function stripFrontmatter(content: string): string {
  const lines = content.split("\n");
  let inFrontmatter = false;
  let frontmatterEnded = false;
  const contentLines: string[] = [];

  for (const line of lines) {
    if (line.trim() === "---") {
      if (inFrontmatter) {
        frontmatterEnded = true;
        continue;
      }
      inFrontmatter = true;
      continue;
    }

    if (frontmatterEnded || !inFrontmatter) {
      contentLines.push(line);
    }
  }

  return contentLines.join("\n").trim();
}

export const SkillsPlugin: Plugin = async ({ client, directory }: PluginInput) => {
  const homeDir = os.homedir();
  const projectSkillsDir = path.join(directory, ".opencode/skills");
  const personalSkillsDir = path.join(homeDir, ".config/opencode/skills");

  return {
    tool: {
      use_skill: tool({
        description: "Load and read a specific skill to guide your work. Skills contain proven workflows, mandatory processes, and expert techniques.",
        args: {
          skill_name: tool.schema
            .string()
            .describe(
              'Name of the skill to load (e.g., "my-custom-skill", or "project:my-skill")',
            ),
        },
        execute: async (args: { skill_name: string }, context: ToolContext): Promise<string> => {
          const { skill_name } = args;

          // Resolve with priority: project > personal
          // Check for project: prefix first
          const forceProject = skill_name.startsWith("project:");
          const actualSkillName = forceProject
            ? skill_name.replace(/^project:/, "")
            : skill_name;

          let resolved: ResolvedSkill | null = null;

          // Try project skills first (if project: prefix or no prefix)
          if (forceProject) {
            const projectPath = path.join(projectSkillsDir, actualSkillName);
            const projectSkillFile = path.join(projectPath, "SKILL.md");
            if (fs.existsSync(projectSkillFile)) {
              resolved = {
                skillFile: projectSkillFile,
                sourceType: "project",
                skillPath: actualSkillName,
              };
            }
          }

          // Fall back to personal resolution
          if (!resolved && !forceProject) {
            resolved = resolveSkillPath(skill_name, personalSkillsDir);
          }

          if (!resolved) {
            return `Error: Skill "${skill_name}" not found.\n\nRun find_skills to see available skills.`;
          }

          const fullContent = fs.readFileSync(resolved.skillFile, "utf8");
          const { name, description } = extractFrontmatter(resolved.skillFile);
          const content = stripFrontmatter(fullContent);
          const skillDirectory = path.dirname(resolved.skillFile);

          const skillHeader = `# ${name || skill_name}
# ${description || ""}
# Supporting tools and docs are in ${skillDirectory}
# ============================================`;

          // Insert as user message with noReply for persistence across compaction
          try {
            await client.session.prompt({
              path: { id: context.sessionID },
              body: {
                noReply: true,
                parts: [
                  {
                    type: "text",
                    text: `Loading skill: ${name || skill_name}`,
                    synthetic: true,
                  },
                  {
                    type: "text",
                    text: `${skillHeader}\n\n${content}`,
                    synthetic: true,
                  },
                ],
              },
            });
          } catch (err) {
            // Fallback: return content directly if message insertion fails
            return `${skillHeader}\n\n${content}`;
          }

          return `Launching skill: ${name || skill_name}`;
        },
      }),
      find_skills: tool({
        description: "List all available skills in the project and personal skill libraries.",
        args: {},
        execute: async (args: Record<string, never>, context: ToolContext): Promise<string> => {
          const projectSkills = findSkillsInDir(projectSkillsDir, "project", 3);
          const personalSkills = findSkillsInDir(personalSkillsDir, "personal", 3);

          // Priority: project > personal
          const allSkills = [...projectSkills, ...personalSkills];

          if (allSkills.length === 0) {
            return "No skills found. Add project skills to .opencode/skills/";
          }

          let output = "Available skills:\n\n";

          for (const skill of allSkills) {
            let namespace: string;
            switch (skill.sourceType) {
              case "project":
                namespace = "project:";
                break;
              default:
                namespace = "";
            }
            const skillName = skill.name || path.basename(skill.path);

            output += `${namespace}${skillName}\n`;
            if (skill.description) {
              output += `  ${skill.description}\n`;
            }
            output += `  Directory: ${skill.path}\n\n`;
          }

          return output;
        },
      }),
    },
  };
};

