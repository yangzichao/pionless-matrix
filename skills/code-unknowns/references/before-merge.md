# Before merge: plan against diff, and a quiz

After merge, other people inherit the change and its unknowns. This pass checks what the diff really does, names who inherits it, and tests whether the user understands it well enough to own it.

## Procedure

1. **Read everything:** the full diff (for example `git diff main...HEAD`), the plan, the deviation log if there is one, and the territory reader's output.

2. **Hold the plan against the diff.** List three things, each with file and line:
   - plan items the diff does not deliver;
   - changes in the diff the plan does not cover: behaviour changes, new dependencies, migrations, config, deleted code;
   - behaviour that callers will see change.

3. **Name who inherits it.** Other callers, other services, existing data and its migration, operations (flags, environment variables, alerts), and the rollback path. List only what the diff actually reaches.

4. **Write the quiz.** Four to six questions the user should be able to answer before merging. Test understanding of what changed, not trivia. Cover at least: one behaviour change, one failure path, one deviation from the plan, and how to roll back. Each question points to the file and line its answer comes from. Put all the answers after all the questions, under a separate heading, so the user can answer first.

5. **Grade the answers.** When the user replies, mark each answer right or wrong. Point every wrong answer to the exact place in the diff that answers it. If the user skips the quiz, that is their call; do not block on it.

## Output shape

1. **Riskiest unknown** in the change, one line, and what to do about it before merging.
2. **Plan against diff:** not delivered; delivered but not planned; what callers will see.
3. **Who inherits it.**
4. **Quiz:** the questions, numbered.
5. **Answers:** after the questions, each with file and line.
6. **Not read:** what you could not reach.

## Example

A 14-file change adds retry to an outbound webhook sender.

**Riskiest unknown.** Retries resend the same payload with no idempotency key (`webhooks/sender.py:77`), so a receiver that already processed the first attempt will process it again. Decide before merging whether to add a key or document it.

**Plan against diff.**

- Not delivered: the plan's "give up after 24 hours"; the diff gives up after 5 attempts (`webhooks/retry.py:12`).
- Not planned: a new `WEBHOOK_MAX_ATTEMPTS` environment variable (`config.py:88`) with no default in the deployment config.
- Callers will see: `send()` now returns before delivery succeeds; it used to block.

**Who inherits it.** Every receiver of webhooks; the on-call engineer, who now needs an alert on the dead-letter table; the deployment config.

**Quiz.**

1. A receiver times out on the first attempt but processed the event. What happens next?
2. Where does a webhook go after the last failed attempt?
3. The plan said 24 hours. What does the code do instead, and where is it set?
4. How do you turn retries off in production?
5. Code that called `send()` and then read the delivery status: what changes for it?

**Answers.**

1. It is sent again with the same payload and no key, so it is processed twice (`webhooks/sender.py:77`).
2. To the `webhook_dead_letters` table (`webhooks/retry.py:40`).
3. Five attempts with backoff, set by `WEBHOOK_MAX_ATTEMPTS` (`config.py:88`).
4. Set `WEBHOOK_MAX_ATTEMPTS=1` (`config.py:88`).
5. `send()` returns before delivery, so the status is "pending", not the final result (`webhooks/sender.py:52`).
