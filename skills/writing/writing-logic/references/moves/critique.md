# Move: critique

A critique paragraph tests whether a claim holds, someone else's or your own. Use it for paper and code reviews, evaluating a proposal, and the risks or open-questions section of your own design doc. This is the GRE Argument essay shape: find what the argument assumes and where the evidence stops short of the conclusion.

## Shape

1. **The claim under test, stated fairly.** One sentence the author would accept as their position.
2. **The gap.** The assumption the claim needs but does not establish, or the point where evidence stops short of the conclusion.
3. **Why it matters.** What happens to the conclusion if the assumption is false. A gap that does not change the conclusion is not worth a paragraph.
4. **What would close it.** The specific evidence, test, or narrower claim that fixes the problem.

## Where gaps usually are

Check these in order; most weak arguments fail on one of the first four.

- **Cause.** A correlation offered as cause. Ask about reverse causation, a third factor that drives both, and timing (did the cause come before the effect?).
- **Sample.** Too few cases, or cases chosen in a way that differs from where the claim is applied: one customer, one benchmark machine, survivors only.
- **Comparison.** No baseline, or the wrong one. "Latency dropped 30%" since when, against what, under the same load?
- **Scope.** The conclusion is broader than the evidence: tested on reads, claimed for all traffic.
- **Analogy.** "It worked at company X" assumes X shares the conditions that made it work.
- **Definitions.** A key word changes meaning between the evidence and the conclusion ("active user" in the metric versus in the claim).
- **Alternatives.** A simpler option that would reach the same result is never considered.

## Rules

- **Rank by damage.** Lead with the gap that would break the conclusion. A list of ten equal-weight nitpicks reads as noise.
- **Be direct and specific.** "The 30% drop compares a Tuesday to a Saturday" beats "the comparison may have some limitations".
- **Separate flawed from false.** Weak support does not make a claim wrong. Say "not shown" when that is all you can say.
- **Critique your own work at the same strength.** In a design doc's risks section, name the assumption most likely to be wrong and what you will watch to find out.
- **If the argument holds, say so** and stop. Do not manufacture objections.

## Check

- For each gap: if the author fixed it, would your assessment change? If not, cut it.
- Does each paragraph end with something the author can do?

## Example

Before: "The proposal has some potential concerns around performance that might need further consideration. Additionally, the evaluation could be more comprehensive."

After: "The proposal claims the new index cuts query time for all tenants, but the benchmark ran only on tenant 7, whose table is 2 GB. Our three largest tenants are over 200 GB, where the index no longer fits in memory, so the gain may reverse. Rerun the benchmark on tenant 12, the largest, before rollout."
