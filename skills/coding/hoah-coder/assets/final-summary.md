# Final summary

Send this to the user when the review loop exits clean.

```text
✓ Task complete after {N} review round(s)

Files changed:
- path/to/file.ts
- path/to/other.ts

Residue (not blocking — your call whether to follow up):

  Improvements ({K}):
  - file:line — concrete suggestion
  - ...

  Nits ({M}):
  - file:line — note
  - ...

  Overturned ({O}) — reviewer flagged but you overruled:
  - file:line — issue (round {N})
  - ...
```

Residue is the `improvement` and `nit` items collected across all review rounds (deduplicated, minus any that later changes already resolved), plus the run-level `overturned_items` list.

If there are zero improvement, nit and overturned items, omit the whole residue section. Omit any empty subsection inside it.
