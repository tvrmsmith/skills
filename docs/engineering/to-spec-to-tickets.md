## What it does

`to-spec-to-tickets` runs three steps in one go: [to-spec](https://aihero.dev/skills-to-spec) writes the conversation up as a spec, three parallel reviewers check that spec, and [to-tickets](https://aihero.dev/skills-to-tickets) breaks it into tracer-bullet tickets on your issue tracker.

The step it adds is the review, and it runs on a spec that is already published. Each reviewer is a [subagent](https://www.aihero.dev/ai-coding-dictionary/subagent) with a fresh [context window](https://www.aihero.dev/ai-coding-dictionary/context-window): it sees the spec and its own reading list, never the conversation that produced it. That is how `to-tickets` and every later implementer will meet the spec, so a reviewer's misreading predicts theirs.

## When to reach for it

You invoke this by typing `/to-spec-to-tickets`, and the [agent](https://www.aihero.dev/ai-coding-dictionary/agent) won't reach for it on its own.

| Where you are | What to run |
| --- | --- |
| Decided, the build spans several sessions, and you want one pass to published tickets | `/to-spec-to-tickets` |
| A spec already exists on the tracker and you want it reviewed, then ticketed | `/to-spec-to-tickets <spec id or file path>`, which skips the writing step |
| You want to stop and read the spec before anything gets sliced | [to-spec](https://aihero.dev/skills-to-spec), then [to-tickets](https://aihero.dev/skills-to-tickets) by hand |
| The work fits one context window | [implement](https://aihero.dev/skills-implement), skip both |
| Nothing is decided yet | [grill-with-docs](https://aihero.dev/skills-grill-with-docs) first |

## Prerequisites

Both halves publish to a tracker, so [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills) must have configured one for this repo. Either kind works: a real tracker like GitHub, or local markdown files under `.scratch/`.

## Three reviewers, three axes

Each reviewer hunts one kind of defect and reports findings without editing anything:

| Reviewer | Reads | Hunts |
| --- | --- | --- |
| Correctness | The spec and the code at the seams it names | Claims about the codebase that are false, seams that do not exist, decisions the code makes infeasible |
| Completeness | The spec and the same code | Error paths, empty and failure states, seams named but never tested |
| Reader | The spec, the glossary and the ADRs | Contradictions between sections, undefined terms, ADR violations, horizontal layering where a vertical slice is available |

The Reader opens with a paraphrase of what the spec proposes. You are shown it verbatim and asked whether it matches what you meant. Where it differs, the spec misleads a fresh reader, and the fix goes into the spec.

Each finding is `clear` or `judgment`. A `clear` finding has one unambiguous correction and is applied. A `judgment` finding is ambiguous, expensive, or a product call, so you are asked, with each option naming the change or skipping it. A reviewer the skill can disprove from a file, an ADR or a spec section is **contested** and the spec is left alone. The amended spec is written back in one update, and a second round runs only if the edits changed the seams, the decisions, or the scope.

## Common questions

**Why not just run `/to-spec` and `/to-tickets` myself?**
You can, and it is the right call when you want to read the spec before slicing it. This skill is for the case where you would have approved the spec anyway: the review catches what a fresh reader would trip over, and it does so before `to-tickets` turns a flaw into several tickets.

**Does it still ask me about seams and the ticket breakdown?**
Yes. It follows both skills to completion, so the seam checkpoint in `to-spec` and the breakdown checkpoint in `to-tickets` still happen. The review adds questions, in the form of the paraphrase check and any `judgment` findings. It does not remove any.

**Can a reviewer rewrite something I decided on purpose?**
Only with your sign-off. If the proof that a decision was deliberate is in a file, an ADR or the spec, the finding is contested and dropped. If it lives only in the conversation, you are asked, with the option to write the decision into the spec so later readers have it too.

**Does it run unattended?**
It has a headless mode for workflow nodes with no human: the review returns its questions as a structured result, and a later session settles them. In a normal session you never see it.

## It's working if

- You are shown a short paraphrase of the spec and can say at a glance whether it is right.
- The spec on the tracker is different after the review, and the report says what changed and what was left alone.
- Findings you are asked about are real decisions, not matters of wording.
- The run ends with the spec id, the applied, contested and skipped counts, and the ticket ids in dependency order.

## Where it fits

`to-spec-to-tickets` collapses two chain steps into one run, with a review between them:

```txt
grill-with-docs → to-spec-to-tickets → implement → code-review → retro
```

It wraps [to-spec](https://aihero.dev/skills-to-spec) and [to-tickets](https://aihero.dev/skills-to-tickets), following each one's `SKILL.md` in the same context window, so the spec never has to be fetched back from the tracker. Downstream, [implement](https://aihero.dev/skills-implement) or [implement-spec](https://aihero.dev/skills-implement-spec) builds the tickets. When you're unsure which skill or flow fits, [ask-matt](https://aihero.dev/skills-ask-matt) routes you.
