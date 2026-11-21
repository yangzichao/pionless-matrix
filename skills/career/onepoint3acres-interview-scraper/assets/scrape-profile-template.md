# `scrape-profile.md` Template

Written to the working directory by Stage 0 (pre-flight Q&A) after the user answers all questions. Every downstream stage reads this file.

## Format

```markdown
# Scrape profile

**Generated**: <YYYY-MM-DD HH:MM>
**Skill version**: 0.2

## User selections

- **company**: <lowercase company slug>
- **titles**: [<SWE | MLE | ResearchScientist | AppliedScientist | DataScientist | DataEngineer | Other:<tag>>, ...]
- **levels**: [<NewGrad | Mid | Senior | Staff | Unspecified>, ...]
- **rounds**: [<VOCoding | SystemDesign | OA | Behavioral | CodePair | TakeHome>, ...]
- **time_window**: <6mo | 1y | 2y | all>

## Derived (filled in by Stage 3 before filtering)

- **role_slug**: <single-title shortcode or dash-joined alphabetical>
- **tid_threshold**: <integer — computed from time_window; 0 if time_window=all>

## Notes

<Optional free-text notes the user added during Q&A. Examples:
 - "skip OA — already prepped that"
 - "interested in MLE rounds even if the post tags SWE — Meta MLE pipelines blur"
 - "only keep posts from candidates who got an offer (search for '收到 offer' / '签了')">
```

## Example: SWE + MLE at Meta, last year, no OA

```markdown
# Scrape profile

**Generated**: 2026-05-23 22:15
**Skill version**: 0.2

## User selections

- **company**: meta
- **titles**: [MLE, SWE]
- **levels**: [Mid, Senior, Unspecified]
- **rounds**: [VOCoding, SystemDesign, CodePair]
- **time_window**: 1y

## Derived

- **role_slug**: mle-swe
- **tid_threshold**: 1145000

## Notes

跳过 OA 因为已经准备过；behavioral 单独有别的资料。
对 MLE ranking / recommender SD 特别感兴趣。
```

## Example: SWE new grad at Coinbase, past 2 years, include OA (Coinbase OAs are substantive)

```markdown
# Scrape profile

**Generated**: 2026-05-23 22:30
**Skill version**: 0.2

## User selections

- **company**: coinbase
- **titles**: [SWE]
- **levels**: [NewGrad, Mid, Unspecified]
- **rounds**: [VOCoding, SystemDesign, OA, CodePair]
- **time_window**: 2y

## Derived

- **role_slug**: swe
- **tid_threshold**: 1020000

## Notes

Coinbase OA 是 real algo + OOD — keep all OA posts with problem statements.
```

## Update protocol

If the user wants to change preferences mid-run, edit this file and re-run from the earliest affected stage:
- Change `titles` / `rounds` / `levels` → re-run Stage 3 onward
- Change `time_window` → re-run Stage 3 (recompute `tid_threshold`)
- Change `company` → restart from Stage 1 (whole new scrape)
