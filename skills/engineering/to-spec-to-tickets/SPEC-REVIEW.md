# Spec review

Review a published spec with three parallel reviewers, then apply what they find. Input: the spec's tracker id or file path, and optionally a decision log from the conversation that produced it.

Read [EXPERIMENT.md](EXPERIMENT.md) first. A reviewer model experiment is running: it sets each reviewer's model and adds a logging step after the spec is written back.

The review runs in one of two modes:

- **Interactive**: a human is reachable in this session.
- **Headless**: no human is reachable, as in a workflow node. The review ends by returning the [headless result](#headless-result), and a later session settles the questions with [Apply answers](#apply-answers).

**Put to the user** means: interactively, ask with `AskUserQuestion` and wait for the answer; headless, add an entry to the result's `questions` and carry on without waiting.

## 1. Dispatch the reviewers

Dispatch three reviewers in parallel, one `Agent` call each in a single message, `subagent_type: general-purpose`, `model: sonnet`, each started with a fresh context window. Give each one the spec's id, its axis, and its reading list, and tell it the reading list is the whole of what it reads. Each reports findings without editing anything.

| Reviewer | Reading list | What it hunts |
|----------|--------------|---------------|
| Correctness | The spec, plus the code at the files and seams the spec names. | Claims about the codebase that are false. Seams that do not exist, or sit lower than an existing seam above them. Decisions the code makes infeasible. |
| Completeness | The spec, plus the code at the files and seams the spec names. | Error paths, empty and failure states, and acceptance-relevant behaviour the spec never names. Seams named but never tested. |
| Reader | The spec, plus the glossary and the ADRs in the area. Pass their paths, collected while writing the spec, or located now if you did not write it. | User stories, implementation decisions, testing decisions and out-of-scope contradicting each other. Project-specific terms that are undefined, unlinked, or outside the glossary. Decisions that violate an ADR. Stories whose value is not end-user observable. Horizontal layering where a vertical slice is available. Sections whose parts do not connect. |

The Reader meets the spec the way `to-tickets` and every implementer first will: without the code or the conversation. It opens its report with a paraphrase under two headings, **What this proposes** and **How the existing system works, per this spec**, two to five sentences each. A section it cannot paraphrase is a finding.

While the reviewers run, if you hold the conversation that produced the spec or a decision log from it, check the spec against it for work the user never asked for. Each piece is a `judgment` finding.

Each reviewer returns one line per finding:

```
<spec section> · clear|judgment · <problem> · <suggested change>
```

`clear` means the correction is unambiguous and any reviewer would make the same edit. `judgment` means ambiguous, expensive, or a product call. An empty findings list is a valid answer.

## 2. Apply the findings

Check the paraphrase first. Put the Reader's paraphrase to the user verbatim, asking whether it matches what they meant. Where it differs, the spec misleads a fresh reader, so record each correction the user names as a `clear` finding.

Dedupe next: one problem often lands on two axes. Keep the sharper wording, and remember every reviewer that raised it.

Then judge each finding before acting on it. The reviewer saw only the spec and its reading list, never the conversation, the same as `to-tickets` and every implementer after it, so its misreading predicts theirs. If you wrote this spec, an urge to push back is not evidence.

- **Valid**: apply every `clear` finding to the spec. Group the `judgment` findings by theme and put each group to the user, each option naming the change to make or skipping it. Apply what the user picks.
- **Contested**: the reviewer is wrong, and you can cite proof it could have read: a file and symbol, an ADR, or a spec section. Leave the spec unchanged and keep the citation for the report. "This was intentional" is not a citation.
- **Escalated**: the reviewer is wrong, but the proof lives only in the conversation. Later readers lack the conversation too, so put the finding to the user alongside the `judgment` groups, with options to write the decision into the spec or skip.

Paraphrase corrections, and Reader findings about undefined terms or disconnected sections, are always valid: when a fresh reader cannot follow the spec, the spec is missing context.

Write the amended spec back to the tracker in one update carrying the full body. Then report one line per applied edit, one per contested finding with its citation, and one per skipped finding.

Run a second round only when the applied edits changed the seams, the implementation decisions, or what is out of scope, and then only with the Correctness and Reader reviewers against the amended spec. Two rounds is the ceiling; finish after that whatever remains.

Done when the amended spec is on the tracker. Interactively, report the applied, contested and skipped counts. Headless, return the headless result.

## Headless result

Return one JSON object, and stop:

| Field | Holds |
|-------|-------|
| `spec_updated` | `true` when you wrote an amended body to the tracker. |
| `applied` | One string per edit applied to the spec. |
| `contested` | One string per contested finding, each ending with its citation. |
| `questions` | Everything put to the user, the paraphrase first. Each entry: `id`, `kind` (`paraphrase`, `judgment` or `escalated`), `reviewers` (the reviewers that raised it), `section`, `text`, and `options` (strings, each naming a change or skipping it). The paraphrase entry's `text` is the paraphrase verbatim, with options `matches` and `has corrections`. |

## Apply answers

A session holding the spec's id, the headless result's `questions`, and the user's answer to each (an option, or free text) settles them here:

1. Apply each picked change to the spec. A paraphrase answer that names corrections is a set of `clear` edits that make the spec read the way the user meant. A skip changes nothing.
2. Write the amended spec back to the tracker in one update carrying the full body.
3. Log the answers as [EXPERIMENT.md](EXPERIMENT.md) describes under "In Apply answers".
4. Report one line per applied edit and one per skipped question.

Run no further review round here: these edits are the user's own calls.
