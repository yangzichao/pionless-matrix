# Review task card

Fill this in for every review round and pass it to the reviewer after the full text of `roles/reviewer.md`. Substitute literal values; never leave a `{placeholder}` in the card.

```text
round: {round}
task: {original user request}
acceptance_criteria:
  - {criterion 1}
  - {criterion 2}
base_ref: {BASE_REF, the literal commit hash}
preferences: |
  {PREFERENCES block, verbatim, or "(none provided)"}
prior_must_fix_summary: |
  {one line per item in prior_must_fix, or "none"}
prior_overturned_summary: |
  {one line per item in overturned_items, or "none"}
```

Summary line format, for both summaries:

```text
- {file}:{line} — {issue}
```

Use `?` for `line` when it is null. In round 1 both summaries are `none`.
