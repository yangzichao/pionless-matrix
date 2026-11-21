# Phase 2 — User Review

Wait for the user's response. Route on intent.

| User says | Action |
|-----------|--------|
| "go" / "start" / "dispatch" / "run" | Proceed to phase 3. |
| "also look for X" / "find more Y" | Rescan the extra scope, append new rows (continue numbering), print a diff of added rows, pause again. |
| "drop #3" / "remove 2,5" / "keep only high" | Edit the queue file, confirm, pause again. |
| User hand-edited the file | Re-read it. Proceed if they also said "go"; otherwise confirm intent. |
| Anything ambiguous | Ask a clarifying question; do **not** dispatch. |

Do not dispatch on a guess. Phase 2 exists specifically to give the user a clean cut point.
