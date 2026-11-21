# Scrape Profile Schema

Defines the structure of `scrape-profile.md`, the per-run preferences file produced by Stage 0 (pre-flight Q&A) and consumed by every downstream stage.

## User-asked fields

### `company` (required, string)
Lowercase company slug used in:
- URL parameter: `&searchoption[3047][value]=<company>`
- Output filenames: `<company>-<role-slug>-by-problem.md`

Examples: `coinbase`, `meta`, `google`, `databricks`, `openai`, `airbnb`.

### `titles` (multi-select, default `[SWE]`)
Job titles the user wants. Drives the per-title KEEP rules in `filter-rules.md`.

| Value | Covers |
|---|---|
| `SWE` | Software Engineer / SDE / Backend / Frontend / Fullstack / Mobile / iOS / Android |
| `MLE` | Machine Learning Engineer / Applied ML / ML Infra / ML Platform |
| `ResearchScientist` | Paper-track research roles (model design from scratch, publication-focused) |
| `AppliedScientist` | Amazon-style applied scientist, applied research with product impact |
| `DataScientist` | DS / product analytics / experimentation / metrics roles |
| `DataEngineer` | Pipeline / Spark / Airflow / Kafka / warehouse roles |
| `Other` | Free text — agent must ask the user for explicit keep rules |

### `levels` (multi-select, default = all values + `Unspecified` ON)
Seniority filter. Most 一亩三分地 posts don't state level — `Unspecified` should usually stay ON.

| Value | Typical mapping |
|---|---|
| `NewGrad` | New grad / entry / L3 / E3 / SDE1 |
| `Mid` | L4 / E4 / SDE2 |
| `Senior` | L5 / E5 / SDE3 |
| `Staff` | L6+ / E6+ / Staff / Principal |
| `Unspecified` | Post does not state level — KEEP unless the user explicitly wants one level only |

### `rounds` (multi-select)
Which round types to keep. Affects Stage 3 + Stage 4 KEEP rules.

| Round | Default | Notes |
|---|---|---|
| `VOCoding` | ON | Onsite / virtual-onsite coding rounds |
| `SystemDesign` | ON | SD / HLD rounds |
| `OA` | ASK | Some companies' OAs are real algorithm problems (Coinbase); others are toy LC mediums (not worth keeping) |
| `Behavioral` | OFF | HM / values / HR rounds; usually drop unless user explicitly wants prep |
| `CodePair` | ON | Live-code pairing sessions |
| `TakeHome` | ASK | Take-home project rounds |

### `time_window` (single-select, default `2y`)

| Value | Meaning |
|---|---|
| `6mo` | Past 6 months — only the most recent rounds |
| `1y` | Past 1 year |
| `2y` | Past 2 years (default — good balance for VO prep) |
| `all` | All-time (NOT recommended — noise grows fast on older posts) |

The time window maps to a tid threshold computed at Stage 3 start. See `filter-rules.md#time-window-to-tid-threshold`.

## Derived fields (computed, not asked)

### `role_slug` (string)
Used in every output filename. Derived from `titles`:
- Single title → lowercase shortcode: `swe`, `mle`, `rs`, `as`, `ds`, `de`.
- Multi-title → dash-joined alphabetical: `mle-swe`, `as-rs`, `ds-mle-swe`.
- `Other` → user-provided short tag.

### `tid_threshold` (integer)
Written to `scrape-profile.md` by Stage 3 once computed. Posts with `tid < tid_threshold` are dropped before semantic filtering.

## File location

`scrape-profile.md` lives in the working directory (next to `<company>-interview-experiences.md`). It is NOT inside `<company>-posts/`. It must survive Stage 6 cleanup — keep it as a record of what was scraped.

See `assets/scrape-profile-template.md` for the literal format.
