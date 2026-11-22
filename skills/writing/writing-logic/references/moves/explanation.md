# Move: explanation

An explanation paragraph makes the reader understand how something works, so they can predict what it will do. Use it for "how it works" sections, READMEs, tutorials, and concept walkthroughs. The logic here is the order of dependencies, not a claim and its defense.

## Shape

1. **What this part does, in the first sentence.** Its job in one line, before any detail. "The scheduler decides which worker runs each job."
2. **The parts, in dependency order.** Introduce a thing before anything that uses it. If B needs A to make sense, A comes first.
3. **The mechanism.** What causes what. Inputs, the step that changes them, outputs. "When a worker misses three heartbeats, the scheduler marks it dead and requeues its jobs."
4. **One concrete case.** Walk a specific input through the mechanism, right after the abstract description or right before it.

## Rules

- **Define before use.** A term the reader has not seen gets one plain definition the first time it appears. A term you coined in this document is not known to the reader.
- **One name per thing.** Once you call it the "scheduler", never switch to "dispatcher" or "coordinator" for variety. A new word signals a new thing.
- **One new idea per sentence.** A sentence that introduces two unfamiliar things loses the reader on the second.
- **Mechanism over description.** "The cache is fast and reliable" describes. "Reads hit the in-memory map first and fall through to disk on a miss" explains. Prefer the second.
- **Example before generalization when the idea is abstract.** For an unfamiliar concept, show the case first, then name the pattern.
- **Do not argue here.** If a sentence defends a choice ("we chose this because..."), it belongs in an argument paragraph. Move it, or cut it to one clause.

## Check

- Give the reader a new input in your head. Could they predict the output from this paragraph alone?
- Scan for any term used before it is defined. Fix the order.

## Example

Before: "The system uses a robust retry mechanism leveraging exponential backoff with jitter to ensure resilience. Failed requests are retried. The backoff helps avoid thundering herds."

After: "When a request fails, the client waits and tries again, up to five times. The wait doubles each attempt (100 ms, 200 ms, 400 ms, and so on), plus a random 0–100 ms. The random part matters when a server restarts: without it, every client that failed at the same moment would retry at the same moment and knock the server over again."
