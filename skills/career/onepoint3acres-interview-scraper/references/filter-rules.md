# Filter Rules (Single Source)

Canonical KEEP/SKIP rules for Stages 3 and 4. The subagent prompts (`extract-batch-prompt.md`, `cluster-fusion-prompt.md`) reference this file — **do not inline-duplicate rules** in any prompt. If a rule changes, change it here and downstream picks it up.

Evaluation order:
1. Hard SKIP
2. Time SKIP (`tid < tid_threshold`)
3. Per-title KEEP
4. Per-level KEEP
5. Per-round KEEP
6. Universal SKIP

---

## Time window to tid threshold

Tid is roughly monotonic with post date on 一亩三分地. Algorithm:

1. Read `time_window` from `scrape-profile.md`.
2. Sample 5–10 random posts spanning the scraped tid range; extract dates via `grep -oE '20[0-9]{2}-[0-9]+(-[0-9]+)?'`.
3. Linear-interpolate the tid corresponding to `today - <window>`.
4. Write the result back to `scrape-profile.md` as `tid_threshold: <int>`.

Rough orientation anchors (recompute per session, do not trust):
- `2y` (as of 2025-05) ≈ `tid >= 1020000`
- `1y` ≈ `tid >= 1130000`
- `6mo` ≈ `tid >= 1180000`
- `all` → no threshold (`tid_threshold: 0`)

---

## Hard SKIP (drop immediately, before any other rule)

- JSON-blob corruption: file starts with `[\n  {` containing only thread metadata (failed scrape).
- Permission-restricted: content equals "提示信息" or body is empty.
- Ghost / 求大米 / 加米-only post (no technical content at all).
- Pure offer-negotiation / BG-check / team-selection / 询问 posts.
- Duplicate tid (already in the master file).

---

## Per-title KEEP rules

For each title in `scrape-profile.md#titles`, keep matching content:

### `SWE`
- KEEP: SWE/SDE VO coding rounds, system design, code pair, OA with substantive problem statements.
- SKIP: MLE-specific (model design, feature engineering, ML system design with model-arch focus), pure Research Scientist topics (paper deep-dive, model derivation from scratch).

### `MLE`
- KEEP: ML system design (recommender / ranking / search / fraud detection / RAG), MLE coding (often LC-style + ML twist), MLE OA, ML behavioral if `Behavioral` in `rounds`.
- ALSO KEEP: pure-SWE coding rounds — most MLE pipelines have at least one algo/coding round.
- SKIP: pure Research Scientist (paper-track), Data Engineer pipeline-only rounds unless ML-adjacent.

### `ResearchScientist`
- KEEP: research presentation rounds, paper deep-dive, model-from-scratch design, math/stats coding, "given a problem design the model" rounds.
- KEEP: ML system design IF the post indicates RS role (often these blur with AS).
- SKIP: pure-SWE LC grinding rounds unless the candidate explicitly notes they were for RS interview.

### `AppliedScientist`
- KEEP: applied ML design (business-impact framing), model debugging case studies, coding (often SWE-style + ML), behavioral.
- Similar to MLE but biased toward "what would you do given this product problem".

### `DataScientist`
- KEEP: SQL rounds, A/B test design, product sense / metrics, experimentation case studies, light coding (Python/pandas/SQL).
- SKIP: heavy distributed systems SD rounds (SWE/MLE territory), low-level coding rounds (DS rounds are usually pad-and-paper or SQL).

### `DataEngineer`
- KEEP: pipeline design (Spark/Airflow/Kafka/Flink), SQL, distributed systems rounds, ETL/stream coding, data modeling.
- SKIP: ML modeling rounds, frontend, mobile.

### `Other`
- Ask user for explicit keep rules during Stage 0 and store them in `scrape-profile.md#notes`. Apply user's stated rules.

When the user selects **multiple titles**, KEEP if **any** title's rules match the post. The Stage 4 extractor will tag each kept post with its matched title(s).

---

## Per-level KEEP rules

Most 一亩三分地 posts do not state level explicitly. Treat the filter as:

- Post **explicitly states** a level NOT in `levels` → SKIP.
- Post **does not state** a level → KEEP iff `Unspecified` in `levels`.
- Post **explicitly states** a level IN `levels` → KEEP.

Level signals to scan for: `L3 / L4 / L5 / L6 / E3 / E4 / E5 / SDE1 / SDE2 / SDE3 / 新人 / 应届 / 转正 / new grad / entry / mid / senior / staff / principal / 高级 / 资深`.

---

## Per-round KEEP rules

After title + level pass, keep only rounds matching `rounds`:

| Round in `rounds` | Indicator phrases in post |
|---|---|
| `VOCoding` | "VO" / "onsite" / "技术轮" / "面试官出题" / explicit coding question text |
| `SystemDesign` | "SD" / "system design" / "设计 X" / "HLD" / architecture diagrams |
| `OA` | "OA" / "online assessment" / "笔试" / "Codility" / "HackerRank" |
| `Behavioral` | "BQ" / "HM" / "behavioral" / "values" / "leadership principle" / "Amazon LP" |
| `CodePair` | "code pair" / "pair coding" / collaborative-coding narrative |
| `TakeHome` | "take home" / "take-home" / "课后作业" / "回家做" / "给一周做" |

If a post contains **multiple round types**, KEEP if any matches `rounds`. The Stage 4 extractor should extract **only the matching round sections**, not the entire post.

---

## Universal SKIP (regardless of profile)

- Pure OA "I got X score, passed" with no problem statement.
- 1-2 sentence posts with no technical substance.
- Reposts of others' posts (no new info — the original is already captured by tid).
- Posts that are purely 流程帖 ("过了 OA / 等结果 / HR 联系" with no round content).

---

## When in doubt

Lean **SKIP**. A 10% noise rate across 300 posts produces 30 garbage downstream entries — better to lose 5 legit posts than to keep 30 noisy ones. Stage 5.5 cross-check cannot recover signal from noise that made it through Stage 3.
