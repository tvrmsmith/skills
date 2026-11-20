# Reviewer model experiment

A live A/B test of Sonnet against Opus for each spec reviewer. It changes two things in the review: which model each reviewer runs on, and a logging step at the end. `scripts/review-experiment.sh` sits beside this file and does the coin flip and the logging.

## Before dispatching

Run `scripts/review-experiment.sh pick`. Dispatch each reviewer on the model it prints, in place of `sonnet`, and keep that model for a second round. Keep the model names to yourself: questions to the user and the review report name reviewers only, so the user's decisions stay blind.

From each reviewer's `Agent` result, keep its total tokens, tool uses and duration.

## After the spec is written back

Log one row per reviewer per round, three rows for round 1 and two more if round 2 ran:

```
scripts/review-experiment.sh log spec=<id> round=<1|2> reviewer=<correctness|completeness|reader> \
  model=<sonnet|opus> runner=<interactive|archon> raw=N clear=N judgment=N deduped=N kept=N \
  unique_kept=N contested=N escalated=N skipped=N tokens=N tool_uses=N duration_ms=N \
  [paraphrase_corrections=N]
```

| Field | Counts |
|-------|--------|
| `raw`, `clear`, `judgment` | Findings the reviewer returned, and their split. |
| `deduped` | Its findings that duplicated another reviewer's. |
| `kept` | Its findings whose edit landed in the spec. A kept finding two reviewers raised counts for both. |
| `unique_kept` | Kept findings no other reviewer raised. |
| `contested`, `escalated` | Its findings triaged that way. |
| `skipped` | Its `judgment` and escalated findings the user declined. |
| `paraphrase_corrections` | Reader only: corrections the user named to the paraphrase. |
| `runner` | `archon` when the review runs as a workflow node, else `interactive`. |

Headless, the user's answers arrive later, so log what this session settled: `kept` counts only edits you applied, and `skipped` is `0`. Leave model names out of the headless result too.

## In Apply answers

Log one row per reviewer that raised at least one question, crediting each answered question to every reviewer in its `reviewers` list:

```
scripts/review-experiment.sh resolve spec=<id> reviewer=<name> kept=N unique_kept=N skipped=N \
  [paraphrase_corrections=N]
```

`kept` counts its questions whose picked change landed in the spec, `unique_kept` those it raised alone, and `skipped` those the user declined. `paraphrase_corrections` goes on the Reader's row.

## Data

Every row is counts and ids. The script has no field for finding text, so spec content stays off disk. Omit `tokens`, `tool_uses` or `duration_ms` only when the `Agent` result did not report it.
