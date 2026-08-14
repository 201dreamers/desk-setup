# Safety & Destructive Action Guardrails

- **Destructive Operations**: Always confirm before executing destructive terminal commands (`rm -rf`, `git reset --hard`, `git push --force`, database drop/truncation).
- **Secrets Protection**: Never expose API keys, credentials, or private tokens in generated files, logs, or commit messages.
- **Backup & Rollback**: Prefer non-destructive edits and verify current git status before undertaking multi-file refactors.
