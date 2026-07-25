---
name: crafting-skills
description: Use when creating or updating skills in `~/.config/ai/skills`, especially when a `SKILL.md` has a weak trigger, tangled structure, poor steering, or bloated wording.
disable-model-invocation: true
---

# Crafting Skills

**REQUIRED SUB-SKILL:** Use `clear-writing` for the final rewrite.

1. Read the target `SKILL.md` and any linked references. Do not edit yet.
2. Interview the user before changing anything. Cover all four: **trigger**, **structure**, **steering**, **pruning**. Use `references/SKILL-CHECKLIST.md`.
3. Decide the smallest honest move: create, rewrite, split, merge, or delete. Ask before split, merge, or delete.
4. Rewrite for the chosen path.
   - **Trigger:** choose user-invoked vs model-invocable on purpose. For user-only skills, set `disable-model-invocation: true`.
   - **Structure:** keep `SKILL.md` tiny. Use numbered steps. Move branch-only reference into supporting files.
   - **Steering:** pick a few leading words and repeat them consistently.
   - **Pruning:** delete sediment, duplication, stale guidance, and no-ops.
5. Bias toward rewrite-after-audit when the old skill is bloated or tangled. Patch in place only when the structure is already sound.
6. Hand off verification. Name the pressure scenarios that should fail without the skill, the deletion tests that prove each paragraph earns its keep, and the next check to run. Do not claim the skill works without evidence.
