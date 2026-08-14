# desk-setup

This repository contains configuration files (dotfiles) for system tools and applications, along with an automated installer script for macOS and Linux (Ubuntu/Debian) environments.

## Repository Layout

```
desk-setup/
├── install.sh             # Installer and symlinking script
├── README.md              # Documentation
└── dotfiles/              # Container folder for all configs
    ├── zshrc              # Shell configuration (~/.zshrc)
    ├── keymaps.ahk        # Windows AutoHotkey keymaps
    ├── ai/                # Unified global AI system (~/.ai)
    │   ├── permissions.json # Master command execution whitelist
    │   ├── sync.py        # Cross-tool config & symlink sync engine
    │   ├── rules/         # Global system rules (Claude, Antigravity, Cursor)
    │   └── skills/        # Shared Agent Skills (28 SKILL.md packages)
    └── config/            # Configurations mapped to ~/.config/
        ├── ghostty/       # Ghostty terminal settings
        ├── nvim/          # Neovim settings
        ├── tmux/          # tmux settings
        ├── vscode/        # VS Code & Cursor settings.json and keybindings.json
        ├── yazi/          # yazi file manager settings
        ├── skhd/          # skhd hotkey daemon config
        ├── yabai/         # yabai tiling window manager config
        └── starship.toml  # starship prompt settings
```

## Setup Instructions

### 1. Clone the repository
Clone this repository to your local machine (recommended location: `~/local/repos/desk-setup`):
```bash
git clone <repository-url> ~/local/repos/desk-setup
cd ~/local/repos/desk-setup
```

### 2. Run the Installer
Run the installation script to check requirements, install dependencies via Homebrew, and link configurations.

#### Standard Interactive Mode (Recommended)
This mode will prompt you for confirmation before backing up and overwriting any existing configurations on your system:
```bash
./install.sh
```

#### Automatic Overwrite/Yes Mode
To run without interactive prompts and automatically back up any conflicting configurations to `<config-path>.bak`:
```bash
./install.sh -y
```

## Features

- **Strict Bash Options**: Runs with `set -euo pipefail` to stop on any errors, undefined variables, or piped failures.
- **Homebrew Check**: Automatically installs Homebrew on macOS if not already present.
- **Generic Linker**: Dynamically symlinks all config folders under `config/` directly to `~/.config/`, meaning you can add new configs to the repository without changing the installer.
- **Robust Backup**: Never overwrites existing dotfiles without backing them up to `.bak` first.
