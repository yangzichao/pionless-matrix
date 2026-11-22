# Back: from an answer to its question

The user already holds an answer, usually a solution, a tool, or a decision, and the questions they ask all serve it: how to use it, which variant to pick, how to convince others. Nobody has said what problem it fixes. Recover the question the answer answers, then check whether the user actually has that question.

## Procedure

1. **Name the answer in hand.** The solution, tool, plan, or decision the questions assume. Quote where it appears.

2. **Recover the question it answers.** State the problem this answer is the standard solution to, without using the answer's name. "Kubernetes" answers roughly "how do we deploy, scale, and heal many services across many machines". If you cannot state the question without the solution's name, you have not recovered it yet.

3. **Check the user against that question.** Does the user have this problem, at this size, now? Look for evidence in the material, and look up facts yourself where you can (the code, the config, the metrics). Three outcomes:
   - **Yes.** The answer fits. Say so briefly and go back to the user's original how-to questions.
   - **No, or not yet.** The answer solves a problem the user does not have. Name the problem they do have, if the material shows it.
   - **Unknown.** The deciding fact is something only the user knows. Ask that one question.

4. **If the answer does not fit, find the real question.** Often it is a Down-style question ("where exactly is it slow") or an Up-style one ("what does 'scale' mean for us").

## Output shape

1. **The answer in hand.** One line, quoting the user.
2. **The question it answers.** One sentence, without the solution's name.
3. **Whether the user has that question.** Yes, no, or unknown, with the evidence.
4. **The real question,** if it differs. One sentence.

Keep it neutral. The point is to check the fit, not to argue the user out of their choice.

## Examples

### Caching

"Redis or Memcached?", "What TTL should the cache use?", "How do I prevent cache stampede?", "Should I add a local second-level cache?"

- **Answer in hand:** a cache.
- **Question it answers:** "the same expensive read happens over and over; how do we avoid repeating it?"
- **Does the user have it?** Unknown. Nobody has profiled the endpoint.
- **Real question:** where exactly is this endpoint slow? If the time goes to one SQL query without an index, all four cache questions are moot.

### "How do I convince my team to adopt Kubernetes?"

- **Answer in hand:** Kubernetes.
- **Question it answers:** "how do we deploy, scale, and recover many services across many machines without doing it by hand?"
- **Does the user have it?** The repo shows three services on one VM, deployed by a script that has not failed this year. So: not yet.
- **Real question:** what is actually painful about deploys today? If nothing is, the team's resistance may be right.

### "Should I build this agent with a graph framework?"

- **Answer in hand:** a graph-based orchestration framework.
- **Question it answers:** "how do we manage a long, branching, stateful flow with retries and checkpoints?"
- **Does the user have it?** Unknown. Ask: does the flow branch, pause for humans, or need to resume after a crash? If it is one model call with two tools in a loop, a plain loop is enough.

### Nothing found

"Which Postgres index type fits a range query on timestamps?", after the user has shown the slow query and its plan.

- **Finding:** the answer in hand (an index) clearly fits the shown problem. Answer the question.
