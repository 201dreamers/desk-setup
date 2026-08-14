---
name: agentic-engineering
description: Use when orchestrating AI agents to do most of the implementation - defining completion/eval criteria before execution, decomposing work into agent-sized units, routing tasks across model tiers (Haiku/Sonnet/Opus), or tracking per-task agent cost. Eval-first, cost-aware agentic engineering.
origin: ECC
---

# Agentic Engineering

For workflows where AI agents do most implementation; humans enforce quality + risk controls.

## Operating Principles

1. Define completion criteria before execution.
2. Decompose into agent-sized units.
3. Route model tiers by task complexity.
4. Measure with evals + regression checks.

## Eval-First Loop

1. Define capability eval + regression eval.
2. Run baseline, capture failure signatures.
3. Execute implementation.
4. Re-run evals, compare deltas.

## Task Decomposition

15-minute unit rule. Each unit:
- independently verifiable
- single dominant risk
- clear done condition

## Model Routing

- Haiku: classification, boilerplate transforms, narrow edits
- Sonnet: implementation, refactors
- Opus: architecture, root-cause analysis, multi-file invariants

## Session Strategy

- Continue session for closely-coupled units.
- Fresh session after major phase transitions.
- Compact after milestone, not during active debugging.

## Review Focus for AI-Generated Code

Prioritize: invariants + edge cases; error boundaries; security + auth assumptions; hidden coupling + rollout risk.

Don't waste review cycles on style-only nits when format/lint already enforce style.

For a high-stakes finding, run 2+ independent subagents with no shared context: convergence on the same top finding is a strong signal it is real; give verifiers distinct lenses when the failure modes differ.

## Cost Discipline

Track per task: model; token estimate; retries; wall-clock; success/failure.

Escalate model tier only when lower tier fails with a clear reasoning gap.
