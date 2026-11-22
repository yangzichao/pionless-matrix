# Paragraph type: argument

An argument paragraph makes the reader believe a claim they might reject. Use it for "why we chose X", position papers, proposals, PR rationale, and any paragraph a skeptic would push back on. This is the GRE Issue essay shape, kept tight.

## Shape

1. **The claim, in the first sentence.** One sentence that takes a position someone could reasonably dispute.
2. **The reason.** Why the claim is true: the mechanism, the principle, or the constraint.
3. **The evidence.** Something concrete the reader can check: a number with its source, a named case, a measurement, a quoted spec, a specific incident with who, when, and what.
4. **The strongest objection, answered.** Only when a real reader would raise it. Name the objection in its strongest form, then say why the claim still holds, or narrow the claim so it does.

Steps 2 and 3 can repeat once for a second reason. More than two reasons usually means the paragraph holds two claims; split it. When a claim rests on several reasons, across one paragraph or several, say how many and mark each: "for two reasons. First, ... Second, ...".

## The claim test

A claim is ready when all of these hold:

- It fits in one sentence.
- It takes a position. "Caching" is a topic; "cache at the edge, not in the service" is a claim.
- Someone informed could disagree with it. "Reliability matters" fails.
- It carries no hedge words ("may", "can sometimes", "in some cases", "it depends"). If the claim is true only under a condition, name the condition: "For read-heavy tables over 10 GB, partition by date."

## Rules

- **Narrow instead of hedging.** When evidence supports less than you claimed, shrink the claim to what it supports and state that at full strength. "This is faster" plus three qualifiers becomes "This halves p95 latency on the read path; writes are unchanged."
- **Every link is nameable.** Between any two adjacent sentences you can say which relation holds: because, therefore, but, for example, so. If you cannot name one, a step is missing or a sentence is in the wrong paragraph.
- **Evidence must be able to fail.** "Users love it" cannot fail. "Weekly retention rose from 31% to 38% after launch" can. Prefer evidence that would have looked different if the claim were false.
- **Never invent evidence.** If a reason has no evidence you know to be true, ask the user for it, mark it as an open gap, or drop the reason.
- **Answer real objections only.** Do not stage an opponent nobody raised. In a design doc, the real objection is usually the best rejected alternative.
- **Claim size matches evidence size.** One incident supports "this can happen", not "this always happens". A benchmark on one machine supports a claim about that machine.

## Check

- Read only the first sentence of each argument paragraph in order. Together they should form the case.
- For each piece of evidence: if it were false, would the claim be weaker? If not, it is decoration; cut it.

## Example

Before: "There are many reasons why Postgres might be a good choice here. It is widely used and has a strong ecosystem. It also offers good performance in many scenarios. Some might argue that DynamoDB scales better, but Postgres can scale too."

After: "Use Postgres for the ledger. Every write touches two balances that must change together, and Postgres gives us that in one transaction; DynamoDB would need TransactWriteItems, which caps a transaction at 100 items and costs twice the write capacity. DynamoDB does scale further, but our peak is 400 writes per second, which a single Postgres primary handled in last month's load test with 70% CPU headroom."
