# Apply answers

Settle the questions a headless spec review left for the user. Inputs: the spec's tracker id or file path, the `questions` array from the review's headless result, and the user's answer to each question, keyed by question `id`. An answer is one of the question's options or free text.

1. Apply each answer to the spec:
   - A picked option that names a change: make that change.
   - A free-text answer to the paraphrase question is the user's corrections: make the `clear` edits that bring the spec to read the way the user meant.
   - Free text to a `judgment` or escalated question: make the change it describes.
   - A skip changes nothing.
2. When at least one change landed, write the amended spec back where it lives (tracker issue or file) in one update carrying the full body.
3. Log the answers as [EXPERIMENT.md](EXPERIMENT.md) describes in its opening section and under "In Apply answers".
4. Report one line per applied edit and one per skipped question, then the applied and skipped counts.

Run no further review round here: these edits are the user's own calls.

Done when every question's answer is applied or skipped, the spec is written back or there was no change to write, and the report is made.
