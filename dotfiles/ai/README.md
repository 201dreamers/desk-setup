# Global AI Configuration Architecture (`~/.ai`)

This directory provides a centralized, tool-agnostic configuration system for AI coding tools including **Claude Code**, **Antigravity (AGY)**, **Cursor**, **Windsurf**, and **GitHub Copilot**.

## Directory Layout

```
~/.ai/
├── README.md               # Architecture documentation
├── sync.sh                 # Synchronization script (links & generates configs)
├── permissions.json        # Whitelist of auto-approved shell commands
├── rules/                  # Shared system rules (Markdown)
│   ├── 01-general.md       # Core engineering principles
│   ├── 02-code-quality.md  # Formatting, documentation & testing standards
│   └── 03-safety-guard.md  # Safety constraints & destructive action guardrails
├── skills/                 # Shared Agent Skills (SKILL.md standard)
│   ├── python-patterns/
│   ├── refactoring/
│   └── ... (28 skills)
└── hooks/                  # Shared agent event hooks
    └── tab-blink.sh        # Tmux tab blinker notification hook
```

## Running Synchronization

To synchronize all skills, rules, permissions, and hooks across installed AI tools:

```bash
bash ~/.ai/sync.sh
```

This command is automatically executed when running `install.sh`.
