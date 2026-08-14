---
name: design-patterns
description: Choose and apply the right Gang of Four design pattern. Use when deciding which pattern fits a problem, refactoring toward or away from a pattern, judging whether a pattern is misapplied in review, or needing the intent, trade-offs, or when-to-use for any of the 23 classic patterns (creational, structural, behavioral).
---

# Design Patterns

Patterns are answers to recurring design problems, not goals. The job here is to **match the symptom** in the code to the pattern that dissolves it, then confirm the pattern's cost is worth paying. Reach for the lightest thing that works: a plain function, a language feature, or no pattern at all often beats a pattern. Every pattern adds classes and indirection - that is the tax you accept in exchange for the specific flexibility it buys.

Source of truth: the 23 Gang of Four patterns - 22 from refactoring.guru plus Interpreter from the original GoF catalog. Full per-pattern detail lives in [`catalog.md`](catalog.md); how patterns relate and evolve lives in [`relations.md`](relations.md).

## Selecting a pattern

1. **State the pressure in plain words.** Name what is actually hurting: something *varies* and forces edits everywhere, two things are *coupled* that should move independently, code is *duplicated*, an object *creation* is tangled, or a *conditional* keeps growing. The pressure, not the noun in the request, picks the pattern.
2. **Read it off the symptom index below** to get one or two candidates. The index is keyed by pressure, not by pattern name.
3. **Open the candidate's entry in [`catalog.md`](catalog.md)** and check its "When to use" against your real situation and its "Cons" against what you can tolerate. If the Cons bite (extra classes, indirection, ordering hazards), that is a reason to stop.
4. **Try the null option.** Would a first-class function, a config value, a built-in collection, dependency injection, or simply deleting the abstraction solve it with less code? If yes, do that instead. Most "overkill" cons in the catalog are warnings against skipping this step.
5. **If two patterns look alike, disambiguate in [`relations.md`](relations.md).** Structure is often identical (Strategy vs State vs Bridge; Decorator vs Proxy vs Composite); intent is what differs.

Completion check: you can name the pressure, the pattern that relieves it, and the con you accepted - or you concluded no pattern is warranted.

## Category cheat-sheet

- **Creational** - control *how objects are made* so creation code does not hard-wire concrete classes. Reach here when `new` is scattered, constructors are exploding, or object families must stay consistent.
- **Structural** - control *how objects are composed* into larger structures while keeping them flexible. Reach here when you are adapting, wrapping, layering, or building trees of objects.
- **Behavioral** - control *how objects communicate and share responsibility*. Reach here when the pain is in algorithms, control flow, growing conditionals, or tangled object-to-object dependencies.

## Symptom index

Match the left column to your situation, then verify the pattern in [`catalog.md`](catalog.md).

### Creating objects (Creational)

- A superclass must create objects but subclasses decide the concrete type -> **Factory Method**
- You must create whole *families* of related objects that have to stay compatible (e.g. matching UI widgets per OS) -> **Abstract Factory**
- A constructor has too many parameters, or the same steps build different representations -> **Builder**
- You need copies of existing objects without depending on their concrete classes -> **Prototype**
- Exactly one shared instance with a global access point is required -> **Singleton** (use sparingly; it is a global and hurts testability)

### Composing objects (Structural)

- An existing class has the wrong interface for your code -> **Adapter**
- One class is exploding along two independent dimensions (abstraction x platform) -> **Bridge**
- You need to treat individual objects and trees of objects uniformly -> **Composite**
- You want to add behavior to individual objects at runtime without subclassing -> **Decorator**
- You want one simple entry point over a complex subsystem -> **Facade**
- You have a huge number of objects and RAM is the bottleneck; state can be shared -> **Flyweight**
- You need to control access to an object (lazy load, cache, protect, log, remote) -> **Proxy**

### Coordinating behavior (Behavioral)

- A request should pass through an ordered, runtime-configurable set of handlers -> **Chain of Responsibility**
- You must parameterize, queue, schedule, log, or undo operations -> **Command**
- You want to traverse a collection without exposing its internals -> **Iterator**
- Many objects communicate in a tangled web; you want to centralize the wiring -> **Mediator**
- You must snapshot and restore an object's state without breaking encapsulation -> **Memento**
- Objects must be notified of another object's changes via subscription -> **Observer**
- An object must change behavior as its internal state changes; state conditionals are growing -> **State**
- You have interchangeable algorithms and want to swap them at runtime -> **Strategy**
- Several classes share an algorithm skeleton but differ in a few steps -> **Template Method**
- You must add operations across a whole object structure without changing its classes -> **Visitor**
- You have a small, stable language or notation to evaluate and can model it as a syntax tree -> **Interpreter**

## Common confusions

- **Strategy vs State** - identical structure. Strategy: the client picks the interchangeable algorithm; the strategies are independent. State: the states know each other and drive transitions; behavior changes on its own as state changes.
- **Decorator vs Proxy** - both wrap an object with the same interface. Decorator *adds behavior* and you stack many; Proxy *controls access* (lazy, cache, protect) and the client usually does not choose it.
- **Adapter vs Facade vs Decorator** - Adapter changes an interface, Facade simplifies a set of interfaces, Decorator keeps the interface and adds behavior.
- **Factory Method vs Abstract Factory** - Factory Method is one method producing one product via subclassing; Abstract Factory is an object producing a family of related products.
- **Bridge vs Strategy** - same shape. Bridge is a structural, up-front split of abstraction from implementation; Strategy is a behavioral, runtime swap of an algorithm.
- **Mediator vs Observer** - both reduce coupling. Mediator centralizes bidirectional wiring in one hub; Observer is a one-way publish/subscribe broadcast.

## Warnings

- Do not add a pattern to satisfy a checklist. A pattern that no current pressure justifies is dead weight - the catalog's most common con is "overkill for simple cases."
- In languages with first-class functions, Strategy, Command, and Template Method often collapse into a function, a callable, or a hook. Prefer that.
- Singleton and Mediator both drift toward god-objects; keep their scope narrow.
