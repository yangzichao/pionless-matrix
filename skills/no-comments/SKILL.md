---
name: no-comments
description: Delete comments in a diff or set of files through an independent Comment Sicko pass, flag the code those comments excuse, fix the accepted findings at the root, and offer to encode claimed constraints as types, tests, or lint. Use when the user asks to strip comments, audit comments in a diff, or run no-comments.
disable-model-invocation: true
metadata:
  version: "1.0.0"
---

# No comments

Dispatch Comment Sicko. Act on accepted findings.

Defer to Comment Sicko's fresh perspective.

Adapted from `skills/no-comments` in backnotprop/pstack (MIT, see `LICENSE`).

## Files

- `roles/comment-sicko.md`: the full Comment Sicko prompt and its report format. Used in step 1.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Dispatch Comment Sicko.
   - If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of `roles/comment-sicko.md`, then the scope. It needs to read and edit files in the scope, and shell plus git to trace history. Do not restate its rules.
   - If you cannot: run the role yourself as a separate pass. Re-read `roles/comment-sicko.md`, work only from the scope, and produce exactly the report it specifies.
2. Inspect its report and diff. Reject application-code edits, scope escapes, exception-protected deletions, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty. Reshape flags on our-code surprises stay actionable. Do not restore those comments. A keep survives only with proof it is about something we cannot change. Audit missed scoped lint and TypeScript suppressions. Correctness or safety suppressions stay actionable `MUST KILL`s. Restore deletions only with exact exceptions and scoped proof. Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, trace their symbol and find out why it exists: if a skill named `why` is available, call it on the symbol; otherwise read `git log -L` or `git blame` for it and the commit that introduced it. If a kill is ambiguous, do not restore. If a keep is refuted or still ambiguous, delete it, except a `REVIEW` keep about an outside rule, which stays until someone checks that rule. Report it open. Revert and rerun one rejected report with the failure named. If you reject the rerun too, revert only its rejected findings, report them open, and go on with the accepted ones.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API. If any fix needs a shape, sketch it once for the accepted set and surrounding code: call the skill named `architect` if it is available, otherwise write the sketch yourself. Stop at the sketch. The sketch shapes. Step 4 implements.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Fix root causes and redesign from first principles in intent only; neither authorizes widening the fence nor fixing instances outside it. Never bolt on symptom guards.
5. Constraint comments say `do not remove`, `do not change wording`, or `talk to X before changing`. Leave keeps about things we cannot change. Offer the cheapest in-scope type, runtime, test, or CI lint. Wait for interactive approval. Unattended and eval runs require caller pre-approval. If approved, encode then delete. Otherwise delete, report the constraint open, and sketch out-of-scope work.
6. Report the deletion count, restored comments, `REVIEW` keeps, reruns, architect sketch, fixes, encoding offers, encodings, unenforced constraints, and other open work.
