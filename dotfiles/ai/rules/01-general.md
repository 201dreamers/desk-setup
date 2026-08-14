# General Development Principles

- **Obey Explicit Directives**: Always enforce layout boundaries, architectural preferences, and explicit rules specified by the user.
- **Never Guess Schemas or Paths**: Inspect actual code source files and schemas using viewing/search tools before making changes.
- **Inspect Error Tracebacks**: Base diagnostics strictly on empirical log evidence and full error tracebacks. Never guess root causes.
- **No Superficial Symptom Patches**: Fix underlying root causes instead of swallowing exceptions or deleting broken tests.
- **Verify Execution**: Gather runtime verification demonstrating success before declaring completion.
