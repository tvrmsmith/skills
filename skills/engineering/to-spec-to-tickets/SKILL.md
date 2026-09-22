---
name: to-spec-to-tickets
description: "Run to-spec, review the resulting spec on four axes with parallel reviewers, then run to-tickets. Use when the user wants one pass from conversation to published tickets."
disable-model-invocation: true
---

# To spec to tickets

One run from conversation to published tickets: `to-spec`, a four-axis spec review, `to-tickets`.

An argument naming an existing spec (tracker id or file path) skips step 1 and reviews that spec instead.

`to-spec` and `to-tickets` both set `disable-model-invocation: true`, so the `Skill` tool cannot call them. Read each one's `SKILL.md` and follow it inline instead:

- `${CLAUDE_PLUGIN_ROOT}/skills/engineering/to-spec/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/engineering/to-tickets/SKILL.md`

## 1. Write the spec

Follow `to-spec` to completion, including its seam checkpoint with the user. It publishes the spec to the project issue tracker. Keep the published spec's id.

## 2. Review the spec

Dispatch four reviewers in parallel, one `Agent` call each in a single message, `subagent_type: general-purpose`, `model: sonnet`. Give each one the spec's id, its axis, and nothing else. Each reads the spec and the code it touches for itself, and reports findings without editing anything.

| Axis | What it hunts |
|------|---------------|
| Correctness | Claims about the codebase that are false. Seams that do not exist, or sit lower than an existing seam above them. Decisions the code makes infeasible. |
| Consistency | User stories, implementation decisions, testing decisions and out-of-scope contradicting each other. Terms outside the domain glossary. Decisions that violate an ADR. |
| Completeness | Error paths, empty and failure states, and acceptance-relevant behaviour the spec never names. Seams named but never tested. |
| Scope discipline | Work the conversation never asked for. Stories whose value is not end-user observable. Horizontal layering where a vertical slice is available. |

Each reviewer returns one line per finding:

```
<spec section> · clear|judgment · <problem> · <suggested change>
```

`clear` means the correction is unambiguous and any reviewer would make the same edit. `judgment` means ambiguous, expensive, or a product call. An empty findings list is a valid answer.

## 3. Apply the findings

Dedupe first: one problem often lands on two axes. Keep the sharper wording.

- Apply every `clear` finding to the spec.
- Group the `judgment` findings by theme and put each group to the user with `AskUserQuestion`, each option naming the change to make or skipping it. Apply what the user picks.

Write the amended spec back to the tracker in one update carrying the full body. Then report one line per applied edit and one per skipped finding.

Run a second round only when the applied edits changed the seams, the implementation decisions, or what is out of scope, and then only with the correctness and consistency reviewers against the amended spec. Two rounds is the ceiling; proceed after that whatever remains.

## 4. Break it into tickets

Follow `to-tickets` to completion against the reviewed spec's id, including its breakdown checkpoint with the user.

Done when the tickets are on the tracker. Close with the spec id, the applied-versus-skipped counts, and the ticket ids in dependency order.
