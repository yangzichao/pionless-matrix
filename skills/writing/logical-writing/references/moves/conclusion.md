# Move: conclusion

A conclusion paragraph answers a question the reader has, so they can act. Use it for replies, status updates, bug diagnoses, decision summaries, and the opening of most documents.

## Shape

1. **The answer, in the first sentence.** Answer the question the reader asked, in their terms. "Yes, ship it Thursday." "The crash comes from the cache key, not the parser." If the reader asked which option, name the option.
2. **What the answer rests on.** One to three facts or reasons, most decisive first. Each is something the reader could check.
3. **What the reader does next.** The decision, step, or approval you need from them, if any. Skip it when nothing is pending.

Background comes after the answer, and only the background this reader lacks.

## Rules

- No run-up. Delete every sentence before the answer that only prepares the reader for it ("I looked into this", "There are a few things to consider").
- One answer. If you have two, the reader asked two questions: answer them in two short paragraphs, most important first.
- State certainty once, precisely. "Verified on staging" or "not verified; the logs stop at 14:02" says more than "likely" or "it seems". Do not spread hedges across every sentence.
- If you do not know, the answer is what you know and what is missing: "Unknown. The two candidates are X and Y; the Z log will decide it."
- Numbers, names, and paths beat adjectives. "p95 went from 840 ms to 210 ms" beats "much faster".

## Check

- Could the reader stop after the first sentence and act correctly?
- Does each later sentence support, qualify, or operationalize that answer? Cut the rest.

## Example

Before: "I spent some time digging into the flaky test. It turns out there are several factors. The test relies on wall-clock time, and the CI machines are sometimes slow. So the fix would probably be to mock the clock."

After: "Mock the clock in `test_session_expiry`. It reads wall-clock time, and on slow CI runners the 50 ms window passes before the assertion runs; it failed 6 of the last 40 runs, all on the shared runners."
