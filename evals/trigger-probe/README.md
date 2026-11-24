# Trigger probe

This probe checks whether Claude Code and Codex load the right skill for a prompt, and only that. It does not judge the output a skill produces.

Each prompt in `trigger_prompts.json` names one skill and expects it either to load (`trigger`) or not to load (`no-trigger`). Near-miss prompts share words with a skill but ask for something else, such as a one-fact lookup instead of deep research. A run stops as soon as any skill loads, so a trigger case costs a few seconds.

## Run it

The hosts read skills from the install copy, so the probe tests whatever `scripts/install-stable-copy.sh` last installed. To probe a description change before merging, link the branch with `scripts/link-skills.sh`, run the probe, then re-run `scripts/install-stable-copy.sh`.

```bash
python3 evals/trigger-probe/run_trigger_probe.py
```

That sends every prompt to both hosts 3 times, 4 at a time. `--runs`, `--hosts`, `--only <prompt-id>...` and `--output-dir` narrow it. Raw event logs and `results.jsonl` go to a temp folder outside the repo; the script prints the path.

Compare a run with the baseline:

```bash
python3 evals/trigger-probe/summarize_results.py <new results.jsonl> evals/trigger-probe/baselines/2026-11-24-r2-results.jsonl
```

Re-run after a model upgrade, a host CLI upgrade, or a change to any skill's `description`. When a result is accepted as the new normal, copy its `results.jsonl` into `baselines/` with the date, and write a `-meta.json` beside it.

## Baseline 2026-11-24-r2 (latest)

Both hosts passed 63 of 63 runs on 21 prompts, after the writing-logic 0.10.3 and writing-ai-tells 4.2.2 descriptions. Those descriptions now lead with the task, say to load the skill even for a short text, list Chinese trigger phrases, and name what they are not for: the assistant's own chat answers, translation, a one-line commit message, a grammar-only fix, and a research briefing.

Six prompts were added for this change. `wl-explicit-4` and `wat-explicit-1` were held out: they were not used to tune the wording, and before the change Claude Code passed them 0 of 3 and 1 of 3. `wl-nearmiss-3`, `wl-nearmiss-4` and `wat-nearmiss-1` guard against the wider wording over-triggering. `wat-explicit-2` reuses the `wl-nearmiss-2` prompt to check that writing-ai-tells loads.

An unchanged prompt can still move between runs. `wl-nearmiss-2`'s prompt loaded writing-ai-tells 0 of 3 times on Claude Code in the first baseline and 3 of 3 times hours later as `wat-explicit-2`, with the same description. Treat a one-run difference as noise.

## Baseline 2026-11-24 (first)

Claude Code (claude-opus-5-5) passed 41 of 45 runs, and Codex (gpt-6.2-sol) passed 45 of 45. No near-miss prompt loaded its skill on either host. Versions and the install commit are in `baselines/2026-11-24-meta.json`.

Claude Code missed in two ways:

- It wrote short writing tasks itself without loading the skill. `wl-explicit-2` (a PR description, "结论先行") never loaded writing-logic, 0 of 3. `wl-nearmiss-2` ("remove the AI-sounding phrasing") never loaded writing-ai-tells either. That case passes, because it only checks that writing-logic stays out, but Codex loaded writing-ai-tells 3 of 3.
- A host-provided skill took one run. `dr-explicit-3` (a source-backed executive briefing) loaded `anthropic-skills:docs` instead of deep-research in 1 of 3 runs. The same Claude Code listing also carries `anthropic-skills:deep-research` and `skill-creator`, which overlap with deep-research and skill-authoring.

The sample is small: one prompt per case and 3 runs each. The Claude Code runs came from a desktop app session, whose skill listing includes claude.ai plugin skills that a plain terminal `claude` may not list.
