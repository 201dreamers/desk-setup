---
name: plan-requirements
description: >-
  Scope a task into v1 boundaries, observable acceptance criteria, failure
  behavior, and clarification questions before coding. Use when the user asks
  to plan a feature, refine requirements, define acceptance criteria, de-risk a
  security/data/migration/integration change, prepare a handoff for another
  agent, says "let's plan", or when a request is ambiguous before implement or
  plan mode. Skip for trivial edits, clear fixes, active debugging, or code review.
---

# Plan requirements

Turn vague/big request into scoped, verifiable spec before code. One primary outcome per request.
Smallest useful output - no ceremony.

## Agent workflow

1. **Detect mode** from message: `plan only`, `implement`, or unclear.
2. **Inspect context first.** Read repo, docs, schemas, tests for technical facts before asking. Repo tells how system behaves today - not what business needs.
3. **Ask only blocking questions** (1-2 max/turn) via AskQuestion. Prefer questions that change code shape, CI, or fail-vs-skip. Group related ones.
4. **Pick depth:** Quick Capture (clear, low/moderate risk) or Full Brief (security, data, migration, cross-system, or handoff).
5. **Plan only** -> template + decisions + phases, no code. **Implement** -> require v1 in/out scope + >=2 AC + failure table (or user waives for trivial fix).
6. **Don't** start coding while user still exploring architecture unless they say implement.

## Depth: Quick Capture

Clear non-trivial change, low/moderate risk. Produce: Goal; in/out scope; assumptions; 3-7 AC with verify method; blocking questions if any. Don't delay implement for approval unless a blocking risk exists or user asked for spec first.

## Depth: Full Brief

Ambiguous, cross-system, security/data/migration/compliance/high-cost, or handoff. Produce full template below. Get confirmation on blocking decisions before risky work.

## Existing spec review

User pasted PRD/issue/plan -> review it, don't restart discovery. Flag missing scope bounds, unverifiable reqs ("system shall be fast"), silent assumptions, contradictions. Return corrected/supplemental criteria.

## Request template (copy, fill)

```text
Goal: <one sentence observable outcome>
Mode: plan only | implement

Constraints (non-negotiable):
- ...

v1 in scope:
- ...
Out of scope (defer, do not build):
- ...

Glossary (new domain terms):
- term: meaning

Acceptance criteria:
- AC-001: <scenario> -> <action> -> <expected observable> -> verify <command/test>
- AC-002: ...

Failure behavior:
| Situation | Expected |
|-----------|----------|
| ... | skip / fail / warn / empty pool |

Verify:
- ruff/mypy <paths>
- pytest <path> -m <marker>
```

## Acceptance criteria - write observable

Each AC = starting condition + trigger + expected observable + prohibited side effect (when meaningful) + verify method + priority (Required/Important/Optional). Tests and AC need not map 1:1.

Ban vague words - "correctly", "secure", "fast", "robust", "intuitive" - unless backed by observable evidence or marked human-judgment.

```
AC-001: Export generates file with correct headers
- Scenario: authenticated user, >=1 data row visible
- Action: click "Export CSV"
- Expected: browser downloads file with columns [id, name, created_at]
- Must not: expose internal fields or other users' rows
- Verify: automated integration test + manual schema spot-check
- Priority: Required
```

Fail example: `AC-001: The export works correctly and is secure.` - no scenario, no observable, no verify. Two readers can't agree it's met.

## Don't infer business rules from code

Repo reveals technical facts (behavior, conventions, contracts). Repo does NOT reveal business rules, compliance/SLA, pricing, retention policy, priority, target users. Capture those from user or product artifact only. Record as assumptions to confirm - never as discovered facts. (E.g. "free tier limited to 100 exports/month" = business rule, not a code fact.)

## Mode labels

| User says | Agent does |
|-----------|------------|
| `Plan only - no code` | Options, decisions, phases only |
| `Pick option X, then implement` | Plan briefly, then code |
| `Implement - scope: ...` | Code within stated scope only |

## Strong requirements

1. **v1 contract** - explicit in/out scope stops mid-flight refactors.
2. **Constraints with why** - e.g. "Greek and Sleet never run one machine, so shared pool field names OK."
3. **Precise reuse** - same file / class / pattern / fixture name (not all of them).
4. **AC over structure** - structure says how; AC says when done.
5. **Failure table** - empty pool, missing YAML fields, offline hardware, missing UI row: skip vs fail vs warn.
6. **Verify block** - commands that prove done, not "should work."

## Ask when missing (blocking only)

- **Scope/mode:** plan or implement? v1 vs deferred? one journey or many (priority)?
- **Config/data:** config path + envs (dev/qa/staging)? YAML required vs optional fields; key rename/migration? incomplete env file -> skip / empty pool / fail?
- **Runtime/pools:** who consumes config (Genos, Sleet, both)? same machine/session - pools contend on one stand? acquire/release rename? delete UI entities on teardown?
- **Tests/CI:** marker shared or product-specific? infra test fail or skip when stand offline/row missing? which runners must pass to merge?
- **Failure table:** empty pool at `request_*`? invalid YAML -> raise or skip+log? pre-provisioned device missing? hardware offline (WG, MAVLink)?
- **Verify:** exact ruff/mypy paths + pytest cmd + marker? which existing tests must stay unchanged?

## Revision mid-implementation

AC can't be met due to architecture/platform/external constraint -> don't silently drop. Mark AC `[revised]`, state constraint, adjust scope/verify, bump revision, re-present ONLY changed AC. Re-confirm only if it changes a blocking decision or cuts a safety/correctness guarantee.

## Safety

- Never put real secrets/creds/tokens/PII/prod payloads in AC, fixtures, examples. Use redacted/synthetic.
- Don't run destructive tests, migrations, security probes, load tests, or paid external calls against prod/live data without explicit auth + a named safe env.
- Don't write brief to repo, create branch, commit, or invoke another skill unless user asks.
- Require confirmation before proceeding only when an unresolved decision risks security exposure, data loss, irreversible migration, contract/API break, real cost, or destructive external action.

## Anti-patterns in requests

Architecture-explore + "start coding" in one message, no mode label; "reuse X" without saying what reuse means; happy path only, no failure behavior; multiple renamed concepts one pass (marker + config + entity tree + pools); "mock later" without stating fixture/param shape.
