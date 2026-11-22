# Sentence style

Write sentences the way a clear scientific paper explains a method: plain, exact, and readable in one pass. Apply these rules while drafting, so the first draft is already plain.

## Rules

- **One sentence, one claim.** If a sentence makes two claims, split it. A reader should never need to reread a sentence to find what it says.
- **Subject, verb, object.** Put the actor in the subject and the action in a concrete verb, close together. "The scheduler requeues the job" beats "Requeuing of the job is performed by the scheduler."
- **Clauses only when they carry logic.** Use a subordinate clause for a condition (`if`, `when`, `unless`), a cause (`because`, `since`), a purpose (`so that`), or a restriction (a defining `that` or `which`). Nest at most one level. Do not use a clause to add a side comment; give the comment its own sentence or cut it.
- **Known before new.** Start a sentence with what the reader already has, from the previous sentence or the context, and end with the new information. This keeps each sentence linked to the one before it.
- **No rhetoric.** No metaphors, similes, rhetorical questions, dramatic fragments, parallel phrasing used for rhythm, or emphasis words such as "truly", "really", "crucially". Established technical terms that started as metaphors (a test harness, a memory leak) are fine.
- **One name per thing.** Define a term the first time it appears, then use exactly that term every time. A new word tells the reader it is a new thing.
- **Exact quantities.** Give numbers with units and, when it matters, the source. Replace vague quantifiers with counts or ranges: "3 of 40 runs" instead of "sometimes", "under 5 ms" instead of "fast".
- **Plain words.** Prefer the short common word when it means the same thing: use, start, show, need, about. Keep the technical term when it is more exact.
- **Number what you announce.** When a sentence says there are several reasons, steps, causes, or options, give the count and mark each item explicitly: "There are three reasons. First, ... Second, ... Third, ...", or a numbered list when each item is short. Do not leave the reader to infer where one item ends and the next begins. Keep the markers even when the items are long, and use the same marker style for the whole list. Repeating the noun ("The first reason is ... The second reason is ...") is good: it reminds the reader which list they are in, and clear structure is worth the repetition.
- **Active voice by default.** Use the passive only when the actor is unknown or does not matter: "The file is deleted after 30 days."

## Length

Most sentences run 10 to 25 words. A longer sentence is fine when it reads in one pass, usually because it has one main clause and one condition or cause. Vary length only as the content requires; do not vary it for rhythm.

## Check

Read each sentence and ask:

1. What is the one claim? If you cannot say it in a few words, split the sentence.
2. Who or what acts? If the answer is hidden, move it into the subject.
3. Does each clause give a condition, cause, purpose, or restriction? If not, cut it or make it a sentence.
4. Is any word there for effect rather than meaning? Cut it.
5. Did a sentence announce several items? Check that each one starts with its marker (first, second, third, or a list number).

## Example

Before: "Crucially, the new caching layer — which we've been iterating on for a while now — dramatically improves things, acting as a shield that protects the database from the relentless storm of read traffic."

After: "The new cache serves reads before they reach the database. In last week's load test, it cut database reads by 82%, from 11,000 to 2,000 per second."
