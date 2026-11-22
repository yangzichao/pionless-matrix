# Eval mode

This needs subagents. Without them, say a blind eval is not possible here, and offer to write the kit (tasks, prompts, rubric, and both skill versions) for the user to run on a host that has them, or to judge by hand.

## Blinding

- Nothing a run sees says eval, test, judge, experiment, rubric, score, compare, benchmark, candidate, or variant: not in folder names, file names, or the prompt.
- The prompt reads like a real user request. State the goal, not what is measured.
- Don't tell a run that other runs exist.
- Don't ask a run which skills or rules it applied. Grade from its output and, when your host shows it, from the files it actually read; never from its own account.
- The judge knows it is judging but sees outputs only under neutral labels (A, B), never by version or model.
- One judge scores every output of a task in one pass, on one scale.

## Steps

1. **Frame.** Name the two versions (old and new skill, or skill and no skill) and what success looks like. Write a rubric of 3 to 6 concrete criteria, for the judge only.
2. **Pick tasks.** Choose 2 to 5 realistic tasks where the change should matter, plus one where it should not, to catch regressions. Use real project material when the user allows.
3. **Set up.** Make one working folder per run, with names a real project would use. Give each run its skill version the way a real host would: installed in the folder's skill directory if your host loads skills from there for subagents, otherwise pasted into the prompt as the project's guide. Both versions get it the same way.
4. **Run.** For each task, start one fresh-context subagent per version with the same prompt, in parallel if your host allows. Run each pair at least twice if the user accepts the cost; one run per version is an anecdote. If your host lets you choose models, give every run the same model.
5. **Judge.** Dispatch the judge with the tasks, the rubric, and the outputs under shuffled labels. Keep the label key to yourself. If your host lets you choose, run the judge on a different model from the runs; otherwise say it ran on the same one.
6. **Read every output yourself**, end to end. Where you disagree with the judge, decide whether the rubric is ambiguous or the judge is biased, and say which.
7. **Report:** the versions, tasks, rubric, notes per output, the judge's verdict, your synthesis, and whether to keep the change.
