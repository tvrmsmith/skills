# Spec review

Review a published spec with three parallel reviewers, then apply what they find. Input: the spec's tracker id or file path, and optionally a decision log from the conversation that produced it.

A reviewer model experiment is running: it sets each reviewer's model and adds a logging step once the review settles. Read the opening, "Before dispatching" and "After the review settles" of [EXPERIMENT.md](EXPERIMENT.md).

The invoker sets the mode:

- **Headless**: the invoking prompt or workflow says to run headless. The review ends by returning the [headless result](#headless-result), and a later session settles the questions with [APPLY-ANSWERS.md](APPLY-ANSWERS.md).
- **Interactive**: every other run.

**Put to the user** means: interactively, ask with `AskUserQuestion` and wait for the answer; headless, add an entry to the result's `questions` and carry on without waiting.

## 1. Dispatch the reviewers

Dispatch three reviewers in parallel, one `Agent` call each in a single message, `subagent_type: general-purpose`, `model: sonnet`, each started with a fresh context window. Give each one exactly this brief: the spec's id; its row of the table below (its reading list and what it hunts), stating that the reading list is the whole of what it reads; the return-line format below, with the `clear` and `judgment` definitions; for the Reader, the paths of the glossary and ADR files in the area, collected while writing the spec or located now if you did not write it; and, for the Reader in round 1, the paraphrase instruction. Each reports findings without editing anything.

| Reviewer | Reading list | What it hunts |
|----------|--------------|---------------|
| Correctness | The spec, plus the code at the files and seams the spec names and the code that calls into them, one level up. | Claims about the codebase that are false. Seams that do not exist, or sit lower than an existing seam above them. Decisions the code makes infeasible. |
| Completeness | The spec, plus the code at the files and seams the spec names. | Error paths, empty and failure states, and acceptance-relevant behaviour the spec never names. Seams named but never tested. |
| Reader | The spec, plus the glossary and ADR files at the paths you are given. | User stories, implementation decisions, testing decisions and out-of-scope contradicting each other. Project-specific terms that are undefined, unlinked, or outside the glossary. Decisions that violate an ADR. Stories whose value is not end-user observable. Horizontal layering where a vertical slice is available. Sections whose parts do not connect. |

The Reader meets the spec the way `to-tickets` and every implementer first will: without the code or the conversation. In round 1 it opens its report with a paraphrase under two headings, **What this proposes** and **How the existing system works, per this spec**, two to five sentences each. A section it cannot paraphrase is a finding. In round 2 it skips the paraphrase.

While the reviewers run, if you hold the conversation that produced the spec or a decision log from it, check the spec against it for work the user never asked for. Each piece is a `judgment` finding from source `main`, which stands in `reviewers` wherever a reviewer would.

Each reviewer returns one line per finding:

```
<spec section> · clear|judgment · <problem> · <suggested change>
```

`clear` means the correction is unambiguous and any reviewer would make the same edit. `judgment` means ambiguous, expensive, or a product call. An empty findings list is a valid answer.

## 2. Apply the findings

In round 1, check the paraphrase first. Put the Reader's paraphrase to the user verbatim, asking whether it matches what they meant. Where it differs, the spec misleads a fresh reader, so record each correction the user names as a `clear` finding.

Dedupe next: one problem often lands on two axes. Keep the sharper wording, and remember every reviewer that raised it.

Then triage each finding. The reviewer saw only the spec and its reading list, never the conversation, the same as `to-tickets` and every implementer after it, so its misreading predicts theirs. If you wrote this spec, an urge to push back is not evidence. Paraphrase corrections, and Reader findings about undefined terms or disconnected sections, are always valid: when a fresh reader cannot follow the spec, the spec is missing context.

- **Valid**: the finding holds, or you believe it wrong but can back that with neither a citation nor the conversation.
- **Contested**: the reviewer is wrong, and you can cite proof it could have read: a file and symbol, an ADR, or a spec section. "This was intentional" is not a citation.
- **Escalated**: the reviewer is wrong, but the proof lives only in the conversation. Later readers lack the conversation too.

Act on the triage:

- Apply every valid `clear` finding to the spec.
- Group the valid `judgment` findings by theme and put each group to the user as one question, each option naming the change to make or skipping it.
- Put each escalated finding to the user alongside those groups, with two options: write the decision into the spec, quoting the exact wording to insert, or skip. The quoted wording lets a later session apply it without the conversation.
- Apply what the user picks.
- Leave the spec unchanged for each contested finding, and keep its citation for the report.

Then finish:

1. When at least one edit landed, write the amended spec back where it lives (tracker issue or file) in one update carrying the full body.
2. Run a second round only when the applied edits changed the seams, the implementation decisions, or what is out of scope. Dispatch only the Correctness and Reader reviewers, against the amended spec. Drop any of their findings that repeats one round 1 already applied, contested, skipped or put to the user (headless: already in `questions`). Take the rest through this section again, from the dedupe through the write-back, then carry on with the steps after this one. Headless, round-2 questions append to the same `questions` array. Two rounds is the ceiling; finish after that whatever remains.
3. Log the review as [EXPERIMENT.md](EXPERIMENT.md) describes under "After the review settles".
4. Interactively, report one line per applied edit, one per contested finding with its citation, and one per skipped finding, then the applied, contested and skipped counts. Headless, return the headless result.

Done when every step above has run.

## Headless result

Return one JSON object, and stop:

| Field | Type | Holds |
|-------|------|-------|
| `spec_updated` | boolean | `true` when at least one edit landed and you wrote the amended body back where the spec lives (tracker issue or file). |
| `applied` | string[] | One string per edit applied to the spec. |
| `contested` | string[] | One string per contested finding, each ending with its citation. |
| `questions` | object[] | Everything put to the user, the paraphrase first, one entry per question: a theme group is one entry, as it is one question interactively. Each entry: `id` (string), `kind` (enum: `paraphrase`, `judgment` or `escalated`), `reviewers` (string[] drawn from `correctness`, `completeness`, `reader`, `main`: the union of sources that raised any finding in the entry, `main` included), `findings` (string[][]: one array per finding the entry bundles, listing the sources that raised it), `section` (string[]: one or more spec sections), `text` (string), and `options` (string[], each naming a change or skipping it). The paraphrase entry's `reviewers` is `["reader"]`, its `findings` is `[]`, its `text` is the paraphrase verbatim, and its only option is `matches`: corrections arrive as a free-text answer. |
