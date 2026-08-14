---
name: refactoring
description: Restructure existing code safely without changing its behavior. Use when improving messy or hard-to-change code, diagnosing a code smell, choosing which refactoring technique to apply, deciding whether a change is worth refactoring first, or reviewing whether code needs cleanup. Covers the 23 code smells and 66 refactoring techniques from refactoring.guru.
---

# Refactoring

Refactoring is changing the *internals* of code while its *observable behavior* stays exactly the same. The whole discipline rests on one rule: move in **small steps and keep the tests green after every step**. A refactoring that changes behavior is a bug, not a refactoring. If there are no tests over the code you are about to touch, add them first - they are what makes the change safe.

Work smell-first: name the specific problem in the code (a **code smell**), then apply the refactorings that dissolve that smell. Do not restructure for its own sake. Full smell detail is in [`smells.md`](smells.md); the full technique catalog is in [`techniques.md`](techniques.md).

## The refactoring loop

1. **Confirm a green test net** over the target code. If it is missing or thin, write characterization tests that pin down current behavior before you touch anything.
2. **Name the smell.** Point at the concrete symptom (long method, duplicated code, feature envy, ...) using the smell index below. If nothing smells, stop - there is nothing to refactor.
3. **Pick the technique** the smell's treatment recommends (see the index, then [`smells.md`](smells.md) for the full treatment and [`techniques.md`](techniques.md) for how each technique works).
4. **Apply one small step**, then run the tests. Green -> commit or continue. Red -> revert that step and take a smaller one. Never batch several refactorings before testing.
5. **Reassess.** One refactoring often exposes or enables the next (Extract Method reveals Move Method reveals Extract Class). Loop until the smell is gone and no new one appeared.

Completion check: behavior is provably unchanged (same tests pass), the named smell is gone, and the diff is a sequence of small, individually safe steps.

## When to refactor - and when not

- **Rule of three** - the third time you copy similar code, refactor the duplication away.
- **Before adding a feature** to code that is hard to change: refactor first so the feature drops in cleanly, then add it.
- **While fixing a bug or in code review** - clean the area you already understand.
- **Do not refactor when** you should be rewriting from scratch (the code is broken beyond repair), or right before a hard deadline - the payoff comes too late and the risk is real. Refactoring near a release freeze is how you ship regressions.

## Smell index (diagnosis)

Find the symptom, get the smell and its go-to techniques. Full treatment in [`smells.md`](smells.md).

### Bloaters - code that has grown too large

- Method too long, needs inline comments to follow -> **Long Method** -> Extract Method, Replace Temp with Query, Decompose Conditional
- Class with too many fields/methods/responsibilities -> **Large Class** -> Extract Class, Extract Subclass, Extract Interface
- Primitives used where a small type belongs (money, ranges, type codes) -> **Primitive Obsession** -> Replace Data Value with Object, Replace Type Code with Class, Introduce Parameter Object
- More than 3-4 parameters on a method -> **Long Parameter List** -> Replace Parameter with Method Call, Preserve Whole Object, Introduce Parameter Object
- The same group of variables travels together everywhere -> **Data Clumps** -> Extract Class, Introduce Parameter Object, Preserve Whole Object

### Object-orientation abusers - OO used wrong

- Complex switch / if-else chain, often on a type code -> **Switch Statements** -> Replace Conditional with Polymorphism, Replace Type Code with Subclasses or State/Strategy
- Fields set only in certain circumstances, empty otherwise -> **Temporary Field** -> Extract Class, Introduce Null Object
- Subclass uses only part of what it inherits -> **Refused Bequest** -> Replace Inheritance with Delegation, Extract Superclass
- Two classes do the same thing with different interfaces -> **Alternative Classes with Different Interfaces** -> Rename Method, Move Method, Extract Superclass

### Change preventers - one change forces many

- One class must change for many unrelated reasons -> **Divergent Change** -> Extract Class (split by reason to change)
- One change forces small edits across many classes -> **Shotgun Surgery** -> Move Method, Move Field, Inline Class (gather it into one place)
- Every subclass here forces a subclass there -> **Parallel Inheritance Hierarchies** -> Move Method, Move Field to collapse one hierarchy

### Dispensables - things that should not exist

- Comments compensating for unclear code -> **Comments** -> Extract Variable, Extract Method, Rename Method (make the code say it)
- Near-identical code fragments -> **Duplicate Code** -> Extract Method, Pull Up Method, Form Template Method
- A class that no longer earns its keep -> **Lazy Class** -> Inline Class, Collapse Hierarchy
- A class that is only fields plus getters/setters -> **Data Class** -> Move Method (move behavior in), Encapsulate Field/Collection
- Code never executed or reached -> **Dead Code** -> delete it; Remove Parameter, Inline Class
- Abstraction built for a future that never came -> **Speculative Generality** -> Collapse Hierarchy, Inline Class, Inline Method, Remove Parameter

### Couplers - classes too entangled

- A method is more interested in another class's data than its own -> **Feature Envy** -> Move Method, Extract Method
- Two classes reach into each other's internals -> **Inappropriate Intimacy** -> Move Method, Move Field, Hide Delegate, Change Bidirectional to Unidirectional
- Chains like `a.getB().getC().getD()` -> **Message Chains** -> Hide Delegate, Extract Method + Move Method
- A class that only forwards calls to another -> **Middle Man** -> Remove Middle Man

### Other

- A library class lacks methods you need but is read-only -> **Incomplete Library Class** -> Introduce Foreign Method (small), Introduce Local Extension (large)

## Technique families

The 66 techniques in [`techniques.md`](techniques.md) fall into six groups - use this to know where to look:

- **Composing Methods** - clean up the inside of methods (extract/inline methods and variables, kill temp-variable tangles).
- **Moving Features between Objects** - put behavior and data in the right class (move/extract/inline classes, methods, fields).
- **Organizing Data** - make data structures clearer and safer (encapsulate fields/collections, replace type codes, model values as objects).
- **Simplifying Conditional Expressions** - tame branching logic (decompose/consolidate conditionals, guard clauses, polymorphism, null object).
- **Simplifying Method Calls** - make interfaces easier to use correctly (rename, add/remove/reorder params, parameter objects, exceptions vs error codes).
- **Dealing with Generalization** - arrange inheritance correctly (pull up / push down members, extract sub/superclass or interface, inheritance vs delegation).

## Warnings

- A refactoring step without a passing test afterward is unverified - treat it as broken until proven green.
- Refactoring is not rewriting and is not adding features. Keep those in separate commits from the behavior-preserving steps.
- Chasing every smell is its own smell. Refactor what blocks the work in front of you; leave cosmetically-imperfect but stable code alone.
- A rename/move/delete is not done until a full-tree grep for the old name returns only intentional hits - sweep code + tests + docs + comments + README/arch diagrams before declaring it complete.
