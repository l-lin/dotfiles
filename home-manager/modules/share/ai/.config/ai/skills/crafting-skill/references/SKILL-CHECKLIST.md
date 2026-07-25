# Skill Checklist

Use this file for the interview and audit.

## Trigger
Ask:
- What exact task should load the skill?
- Should it be user-invoked or model-invocable?
- Does the description name the problem and symptoms, not the workflow?
- Would the name help someone find it from `/skill:`?

## Structure
Ask:
- Is this a new skill or an update?
- Is one skill enough, or are there real branches?
- What must stay in `SKILL.md` every run?
- What belongs in `references/` because it is heavy or branch-only?

## Steering
Ask:
- What leading words should repeat?
- What bad behavior must the wording correct?
- Does any step need more leg work than a combined skill will give it?
- Is the desired output shape obvious?

## Pruning
Ask:
- What is duplicated, stale, or branch-only?
- What sentence can you delete with no behavior change?
- Does every paragraph earn its tokens?
- Is there a smaller honest skill here?

## Verification
- Pressure scenario: compare behavior without the skill and with it.
- Deletion test: remove a line. If behavior does not regress, keep it out.
- Discovery test: can the user choose the skill from name and description alone?
- For discipline skills, use `references/PERSUASION-PRINCIPLES.md` only if plain guidance fails.

## Example
Bad description:

```yaml
description: Use for writing skills, auditing them, fixing the structure, and testing them thoroughly.
```

Better description:

```yaml
description: Use when creating or updating skills in `~/.config/ai/skills`, especially when a `SKILL.md` has a weak trigger, tangled structure, poor steering, or bloated wording.
```

Why it is better: it describes the trigger, not the workflow.
