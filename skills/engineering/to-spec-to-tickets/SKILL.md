---
name: to-spec-to-tickets
description: "Run to-spec, review the resulting spec with three parallel reviewers, then run to-tickets. Use when the user wants one pass from conversation to published tickets."
disable-model-invocation: true
---

# To spec to tickets

One run from conversation to published tickets: `to-spec`, a three-reviewer spec review, `to-tickets`.

An argument naming an existing spec (tracker id or file path) skips step 1 and reviews that spec instead.

`to-spec` and `to-tickets` both set `disable-model-invocation: true`, so the `Skill` tool cannot call them. Read each one's `SKILL.md` and follow it inline instead:

- `${CLAUDE_PLUGIN_ROOT}/skills/engineering/to-spec/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/engineering/to-tickets/SKILL.md`

## 1. Write the spec

Follow `to-spec` to completion, including its seam checkpoint with the user. It publishes the spec to the project issue tracker. Keep the published spec's id.

## 2. Review the spec

Read [SPEC-REVIEW.md](SPEC-REVIEW.md) and follow it to completion against the spec's id.

## 3. Break it into tickets

Follow `to-tickets` to completion against the reviewed spec's id, including its breakdown checkpoint with the user.

Done when the tickets are on the tracker. Close with the spec id, the applied, contested and skipped counts, and the ticket ids in dependency order.
