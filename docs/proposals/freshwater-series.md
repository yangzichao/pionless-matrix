# Freshwater: A Math Research Agent Series

> **Status: proposal — only `freshwater-doctor` exists; the rest of the series is design-only.**

This document captures the design intent, landscape research, and skill roadmap for the **`freshwater-*`** series — a family of skills inside `pionless-agent` aimed at a working mathematician / mathematical econometrician who needs both **symbolic computation** and **formal proof** support in their daily research.

The first skill (`freshwater-doctor`) has shipped as a starting point; the remaining skills are open design questions captured here so the thinking is not lost.

---

## 1. Motivation

A research mathematician doing measure theory, asymptotic statistics, and econometric theory needs two distinct capabilities from an LLM agent:

1. **Compute** — run a symbolic integral, expand a series asymptotically, manipulate a matrix expression, evaluate an expectation under a specific distribution. The LLM cannot reliably do this itself; it must delegate to a CAS (Mathematica, SymPy, SageMath).
2. **Formalize / prove** — write rigorous proofs of measurability, dominated convergence, asymptotic normality, etc. The LLM can draft Lean code but needs an interactive proof assistant in the loop to keep it honest.

Today these two capabilities live in **separate** ecosystems, and an individual researcher must wire them together by hand. The freshwater series is an opinionated take on what that wiring looks like as a coherent agent surface.

---

## 2. User profile

The target user is a working researcher with the following shape:

- **Domains**: measure theory, probability, asymptotic statistics, econometric theory (especially modern semiparametric methods like double machine learning), domain theory.
- **Daily activities**: deriving expectations / asymptotic expansions; writing proofs that mix probability, analysis, and linear algebra; reading papers and translating their key lemmas into formal statements.
- **Tooling baseline**: comfortable on the command line, uses Claude Code, has not previously installed Lean / Mathematica.
- **Constraints**: cost-sensitive (prefers free tools); willing to use Wolfram Engine because it is free for development; values rigor over convenience.
- **Allergic to**: pretentious naming, half-finished features, agent flows that do too much without asking.

The series is **not** designed for:
- Olympiad / competition math (DeepSeek-Prover-V2 territory — `miniF2F`-style problems).
- Pure software engineering (already covered by `hoah-coder`).
- Survey writing (`deep-research` covers that).

---

## 3. Landscape — what already exists

The proposal exists because nothing in 2026 ships the unified compute + proof + research-loop surface this user needs. Closest neighbors (research as of 2026-04):

### Proof-only

- **`lean4-skills`** (Cameron Freer) — formalize / prove / review / golf loop, Mathlib search, axiom checks. Host-agnostic Claude Code skill. [github.com/cameronfreer/lean4-skills](https://github.com/cameronfreer/lean4-skills)
- **Numina-Lean-Agent** (Project Numina, 2026-01) — Claude Code + `lean-lsp-mcp` + LeanDex retrieval; reportedly solved all 12 Putnam 2025 problems with Opus 4.5. Strong proof workflow, no CAS side. [github.com/project-numina/numina-lean-agent](https://github.com/project-numina/numina-lean-agent)
- **Ax-Prover** (AxiomMath, 2025-10) — multi-agent Lean prover via MCP, math + quantum physics. [arxiv.org/abs/2510.12787](https://arxiv.org/abs/2510.12787)
- **`leanprover/skills`** — official Lean org skill pack including a `lean-setup` doctor (Lean-only). [github.com/leanprover/skills](https://github.com/leanprover/skills)

### CAS-only

- **Wolfram/MCPServer** — official Wolfram MCP paclet, v1.9.0 (2026-04-08), MIT, ships with Wolfram Engine. Per-call timeout suggests stateless evaluation; cross-call symbol persistence requires verification. [resources.wolframcloud.com/PacletRepository/resources/Wolfram/MCPServer/](https://resources.wolframcloud.com/PacletRepository/resources/Wolfram/MCPServer/)
- **`AbhiRawat4841/mathematica-mcp`** — community MCP with explicit persistent kernel state (`set_variable`, `get_kernel_state`). Best community option for multi-step derivations. [github.com/AbhiRawat4841/mathematica-mcp](https://github.com/AbhiRawat4841/mathematica-mcp)
- **`sdiehl/sympy-mcp`** — open-source CAS over MCP. The right fallback for users unwilling to install Wolfram. [github.com/sdiehl/sympy-mcp](https://github.com/sdiehl/sympy-mcp)

### Closest unified attempt

- **Math Intelligence Router** — Claude skill that routes natural-language intent to SymPy / Z3 / Pint / Lean CLI. *Routes intent only*; no research loop, no notes, no citation pipeline.

### What no-one ships

A single Claude Code surface that:

1. Bundles a CAS MCP and a Lean MCP under one user-facing flow.
2. Provides a research workflow — compute → conjecture → formalize → cite → take notes — not just intent routing.
3. Includes a doctor skill that diagnoses both halves of the stack plus the wiring between them.

The freshwater series fills (3) first (already built), with (1) and (2) sketched below.

---

## 4. Naming

The prefix is **`freshwater-`**.

The pun is intentional and tribal:

- *Freshwater economics* (Hall, 1976) is the umbrella term for the rational-expectations / RBC tradition centered at **Chicago, Minnesota, Rochester, Carnegie Mellon** — schools physically on the Great Lakes. It is paired against *saltwater economics* (Harvard, MIT, Berkeley, Princeton), more policy-flavored New Keynesian work.
- The freshwater tradition is associated with mathematical rigor, axiomatic taste, and a comfort with abstraction — exactly the disposition the target user brings to research.
- "Freshwater" reads as cool, slightly aloof, and self-aware without being pretentious. It is recognizable to economists, opaque enough to be mysterious to non-economists, and unique as a software prefix.

Skills in the series share the `freshwater-` prefix so they cluster in the user's slash-command list. The shared prefix is also a cheap form of namespacing against future skill collisions.

---

## 5. Series roadmap

| Skill | Status | Job |
|---|---|---|
| **`freshwater-doctor`** | **built** | Diagnose the local math stack (Lean toolchain, Mathlib project, MCP servers, optional Wolfram). Recommends the next install step. Read-only. |
| **`freshwater-prove`** | proposed | Drive a Lean 4 + Mathlib formalization loop: parse goal state via `lean-lsp-mcp`, search lemmas via `lean-explore`, draft tactics, iterate to `sorry`-free. |
| **`freshwater-compute`** | proposed | Drive a CAS workflow: route a natural-language calculation request to Wolfram MCP (preferred) or `sympy-mcp` (fallback); maintain a persistent kernel session for multi-step derivations. |
| **`freshwater-cite`** | proposed | Search Mathlib for an existing lemma that matches a user-provided informal claim. Returns Lean lemma name + applicable rewrite. Could absorb `lean-explore` semantic search. |
| **`freshwater-asymptotic`** | proposed | Specialization of `freshwater-compute` for asymptotic expansions (Edgeworth, saddlepoint, delta method). Pre-loaded prompts and assumption boilerplate. |
| **`freshwater-research-loop`** | proposed | The umbrella workflow: take a research question, alternate between `compute` and `prove` to make progress, and persist a running notebook (output location TBD — see §7). The "main entry point" of the series for end users. |

This list is the working scope. Any specific skill may be dropped, merged, or renamed during implementation; the prefix stays.

---

## 6. Architecture sketch

The series rests on a four-layer stack:

```
┌─────────────────────────────────────────────────────────┐
│ Claude Code (driver)                                    │
│   └─ freshwater-* skills (this series)                  │
├─────────────────────────────────────────────────────────┤
│ Compute side                  │ Proof side              │
│   wolfram MCP (preferred)     │   lean-lsp-mcp          │
│   sympy-mcp (fallback)        │   lean-explore mcp      │
├─────────────────────────────────────────────────────────┤
│ Wolfram Engine (optional)     │ Lean 4 + Mathlib        │
│   - free for developers       │   - Apache 2.0          │
│   - 60s per-call timeout (?)  │   - elan-managed        │
├─────────────────────────────────────────────────────────┤
│ uv / uvx, python3, claude CLI (glue)                    │
└─────────────────────────────────────────────────────────┘
```

Wolfram side is **optional by design** — the series should be useful even with the proof side alone, and even the proof side alone is more value than most researchers have today.

---

## 7. Open design questions

- **Wolfram MCP kernel persistence.** The official `Wolfram/MCPServer` paclet has a 60-second per-call timeout; whether it persists symbol bindings across calls is undocumented. If it doesn't, `freshwater-compute` should default to `AbhiRawat4841/mathematica-mcp` (which advertises persistent state) or `sympy-mcp` (Python class held in module memory). **Decision deferred until empirical test.**
- **Should `freshwater-cite` exist as its own skill, or be folded into `freshwater-prove`?** The Lean workflow inevitably needs lemma search; a separate skill might be over-decomposition. **Lean: probably fold in unless lemma search becomes a standalone task.**
- **Research-loop output convention.** The CLAUDE.md project-level convention is to write research output to `deep-research/`. Should `freshwater-research-loop` write there too, or to a new `math-research/`? Probably `deep-research/` with a topic-tag prefix — keeps tooling consistent.
- **Cross-platform support.** The pionless-agent plugin ships to both Claude Code and Codex. The freshwater series leans on MCP (Claude-only). Does the Codex bundle ship the SKILL.md as a no-op stub, or does it omit the skills entirely? **Likely Claude-only for v1**, revisit when Codex MCP support matures.
- **Versioning.** New skills bump `0.X.0` per the project's version cadence convention. The series should be added incrementally, one skill per minor bump, not as a single 0.6.0 mega-release.

---

## 8. Out of scope

- **Shipping a prover model.** No fine-tuned DeepSeek-Prover / Goedel / Kimina is bundled. The series uses the user's chosen LLM (Claude) plus retrieval, not a specialized prover. Local prover models can be added later as an optional fallback `freshwater-fallback-prover`, but they are explicitly not core.
- **Math typesetting / PDF rendering.** Already covered by `markdown-to-pdf`. `freshwater-research-loop` should hand off to it rather than re-implement.
- **Survey / literature review.** Already covered by `deep-research`. A research-math investigation can spawn a `deep-research` sub-agent for "what's been done on X" queries, but the freshwater series itself does not do paper search.
- **Cloud-hosted CAS or proof services.** The series targets a local stack. The hosted Wolfram MCP Service (which is documented as stateless) is explicitly avoided; remote proof services (e.g. Leanstral via Mistral Labs) may be optional alternatives but are not the default.
- **Olympiad / competition problems.** This series is for working research math, not benchmark chasing.

---

## 9. References

- [Verdict: Wolfram Engine + official MCP paclet exists; community persistent-kernel alternative also strong](https://www.wolfram.com/artificial-intelligence/mcp-server/) — Wolfram Research, 2026.
- [`oOo0oOo/lean-lsp-mcp`](https://github.com/oOo0oOo/lean-lsp-mcp) — load-bearing MCP server for the proof side.
- [`justincasher/lean-explore`](https://github.com/justincasher/lean-explore) — Mathlib semantic search, beats LeanSearch on relevance benchmarks.
- [`cameronfreer/lean4-skills`](https://github.com/cameronfreer/lean4-skills) — closest existing Claude Code skill pack for the Lean side.
- [`leanprover/skills`](https://github.com/leanprover/skills) — official Lean skills, including `lean-setup` (doctor for Lean-only).
- [`sdiehl/sympy-mcp`](https://github.com/sdiehl/sympy-mcp) — open-source CAS-over-MCP fallback.
- [Hall (1976)](https://en.wikipedia.org/wiki/Saltwater_and_freshwater_economics) — origin of the freshwater / saltwater dichotomy this prefix borrows.

---

## 10. Decision log

| Date | Decision | Rationale |
|---|---|---|
| 2026-04-30 | Prefix is `freshwater-`. | Coolest of several econometrics-themed candidates; carries a real economics inside joke; unique as software prefix; ties the series to the user's discipline without being self-important. |
| 2026-04-30 | First skill is `freshwater-doctor`, not a workflow skill. | The diagnostic is the smallest independently-useful piece; ships now without committing to the full series; gives the rest of the family a healthy substrate to build on. |
| 2026-04-30 | Wolfram side is optional, not blocker. | User explicitly hedged on whether they want Wolfram. Proof side is more load-bearing for their actual work. |
| 2026-04-30 | Skill series lives in `pionless-agent`, not a separate plugin. | Same architectural pattern as `report-style-*`, `deep-research`, `hoah-coder`. No reason to fragment the plugin surface. |

