# Reviewer model experiment

A live A/B test of Sonnet against Opus for each spec reviewer. It changes two things in the review: which model each reviewer runs on, and a logging step at the end. The helper script does the coin flip and the logging. It is `scripts/review-experiment.sh` in the same directory as this file. Your working directory is the user's project, so run it by its absolute path, written `<base>/scripts/review-experiment.sh` below, where `<base>` is the absolute path of the directory holding this file.

Findings from source `main` belong to no reviewer. Leave them out of every row and every count in every section below, and never pass `reviewer=main`. So a finding `main` shares with exactly one reviewer counts for that reviewer as unique and not deduped.

## Before dispatching

Run `<base>/scripts/review-experiment.sh pick`. Dispatch each reviewer on the model it prints, in place of `sonnet`, and keep that model for a second round. Keep the model names to yourself: questions to the user, the review report and the headless result name reviewers only, so the user's decisions stay blind.

From each reviewer's `Agent` result, keep its total tokens, tool uses and duration.

## After the review settles

Log one row per reviewer per round, three rows for round 1 and two more if round 2 ran.

```
<base>/scripts/review-experiment.sh log spec=<id> round=<1|2> reviewer=<correctness|completeness|reader> \
  model=<sonnet|opus> runner=<interactive|archon> raw=N clear=N judgment=N deduped=N kept=N \
  unique_kept=N contested=N escalated=N skipped=N [tokens=N] [tool_uses=N] [duration_ms=N] \
  [paraphrase_corrections=N]
```

Pass `tokens`, `tool_uses` and `duration_ms` whenever the `Agent` result reports them, and omit each one it did not report.

| Field | Counts |
|-------|--------|
| `raw`, `clear`, `judgment` | Findings the reviewer returned, and their split. |
| `deduped` | Its findings that merged with another reviewer's. A merge counts on every reviewer in it. |
| `kept` | Its findings whose edit landed in the spec. A kept finding two reviewers raised counts for both. |
| `unique_kept` | Kept findings no other reviewer raised. |
| `contested`, `escalated` | Its findings triaged that way. |
| `skipped` | Its `judgment` and escalated findings the user declined. |
| `paraphrase_corrections` | Reader only: corrections the user named to the paraphrase. They count here alone, never in `raw`, `clear` or `kept`. |
| `runner` | `archon` when running headless, else `interactive`. |

A finding in a theme-group question is credited with that question's outcome: every finding in the group counts as kept, or skipped, together.

Headless, the user's answers arrive later, so log what this session settled: `kept` counts only edits you applied, and `skipped` is `0`.

## In Apply answers

Count findings, crediting each with its question's outcome per the rule under the field table. An answered question credits each finding it bundles, per its `findings` arrays, to every reviewer that raised that finding. Log one row per reviewer named in any answered question's `reviewers`, `main` excluded, summing its counts across all answered questions:

```
<base>/scripts/review-experiment.sh resolve spec=<id> reviewer=<name> kept=N unique_kept=N skipped=N \
  [paraphrase_corrections=N]
```

`kept`, `unique_kept` and `skipped` mean what they do on the review row. `paraphrase_corrections` goes on the Reader's row, and nowhere else.

## Escaped gaps

When an implementer or a later stage hits a spec gap the review should have caught, log it against the reviewer whose area it falls in. This usually runs by hand, or when the user asks:

```
<base>/scripts/review-experiment.sh escaped spec=<id> reviewer=<correctness|completeness|reader>
```

## Data

Every row is counts and ids. The script has no field for finding text, so spec content stays off disk.
