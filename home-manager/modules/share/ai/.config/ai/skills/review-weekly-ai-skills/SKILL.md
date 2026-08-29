---
name: review-weekly-ai-skills
description: Evaluate AI skill usefulness over the last 7 days
disable-model-invocation: true
---

Review my last 7 days of `pi` sessions and evaluate every skill in `~/.config/ai/skills/`.
Use session evidence and counts where helpful.
Judge required or default-loaded skills separately from manual skills.
For skills with `disable-model-invocation: true`, do not treat lack of automatic loading as a failure. Judge them by whether explicit invocations were appropriate, whether they changed the workflow in a useful way, and whether the extra token or tool cost paid off.
For skills without `disable-model-invocation: true`, weigh token cost, false positives, missed triggers, and real value.
Group verdicts as `Helped`, `Hurt`, or `Unclear`, marking untouched skills `Unclear, unused this week`.
Be blunt, and for major findings give one concrete example and one next action: keep, tune, merge, archive, or remove.
