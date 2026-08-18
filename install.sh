#!/usr/bin/env bash

# Setup strict shell options for reliability
set -euo pipefail

# Text colors for clean logging
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 1. Parse command-line arguments
AUTO_BACKUP=false
FORCE_OVERWRITE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            AUTO_BACKUP=true
            shift
            ;;
        -f|--force|--no-backup)
            FORCE_OVERWRITE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -y, --yes          Automatically backup and overwrite existing configuration files"
            echo "  -f, --force        Force overwrite existing configuration files without creating .bak backups"
            echo "  --no-backup        Alias for --force"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [-y|--yes] [-f|--force|--no-backup]"
            exit 1
            ;;
    esac
done

# 2. Platform detection
log_info "Detecting system platform..."
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    IS_MACOS=true
    IS_LINUX=false
    log_success "macOS detected."
elif [[ "$OS" == "Linux" ]]; then
    IS_MACOS=false
    IS_LINUX=true
    log_success "Linux system detected."
else
    log_error "Unsupported operating system: $OS"
    exit 1
fi

# 3. Ensure Homebrew is installed and configured in PATH
if ! command -v brew &>/dev/null; then
    # Check common Homebrew installation paths for macOS or Linux
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
fi

# 4. Install dependencies
PACKAGES=(
    uv
    neovim
    tmux
    yazi
    starship
    lazygit
    ghostty
)

# Add macOS-specific window management packages
CASK_PACKAGES=()
if [ "$IS_MACOS" = true ]; then
    PACKAGES+=(yabai skhd)
    CASK_PACKAGES+=(hammerspoon)
fi

if command -v brew &>/dev/null; then
    log_info "Installing dependencies via Homebrew..."
    for pkg in "${PACKAGES[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log_info "$pkg is already installed."
        else
            log_info "Installing $pkg..."
            brew install "$pkg" || true
        fi
    done
    for pkg in "${CASK_PACKAGES[@]}"; do
        if brew list --cask "$pkg" &>/dev/null; then
            log_info "$pkg is already installed."
        else
            log_info "Installing $pkg (cask)..."
            brew install --cask "$pkg" || true
        fi
    done
    log_success "Homebrew dependencies ready."
elif [ "$IS_LINUX" = true ] && command -v apt-get &>/dev/null; then
    log_info "Homebrew not found. Installing packages via apt-get where available..."
    sudo apt-get update -qq || true
    for pkg in neovim tmux zsh curl git; do
        log_info "Checking $pkg..."
        sudo apt-get install -y "$pkg" || true
    done
else
    log_info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
        for pkg in "${PACKAGES[@]}"; do
            brew install "$pkg" || true
        done
        for pkg in "${CASK_PACKAGES[@]}"; do
            brew install --cask "$pkg" || true
        done
    fi
fi

# 5. Backup & Symlinking Functions
# $1 - source (absolute path in repo)
# $2 - destination (absolute path in home)
link_config() {
    local src="$1"
    local dest="$2"

    # If the destination is already a symlink pointing to the correct source, skip
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        log_info "Configuration $dest is already correctly linked."
        return
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [ "$FORCE_OVERWRITE" = true ]; then
            log_info "Force overwriting $dest without backup..."
            rm -rf "$dest"
            mkdir -p "$(dirname "$dest")"
            ln -s "$src" "$dest"
            log_success "Linked: $dest -> $src"
        elif [ "$AUTO_BACKUP" = true ]; then
            backup_and_link "$src" "$dest"
        else
            echo -n "File/directory $dest already exists. Back up and overwrite? [y/N] "
            read -r reply
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                backup_and_link "$src" "$dest"
            else
                log_info "Skipped linking for $dest."
            fi
        fi
    else
        # Destination doesn't exist, create parent folders and link
        mkdir -p "$(dirname "$dest")"
        ln -s "$src" "$dest"
        log_success "Linked: $dest -> $src"
    fi
}

backup_and_link() {
    local src="$1"
    local dest="$2"
    local backup="${dest}.bak"

    # Avoid overriding a previously created backup by adding a timestamp if needed
    if [[ -e "$backup" || -L "$backup" ]]; then
        backup="${dest}.$(date +%Y%m%d%H%M%S).bak"
    fi

    log_info "Backing up existing $dest to $backup"
    mv "$dest" "$backup"
    
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log_success "Linked: $dest -> $src"
}

# 6. Run linking logic
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
REPO_CONFIG_DIR="$DOTFILES_DIR/config"

log_info "Creating configuration symlinks..."

# Link .zshrc
link_config "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

# Dynamically link all packages inside the repo config/ directory to ~/.config/
if [[ -d "$REPO_CONFIG_DIR" ]]; then
    for item in "$REPO_CONFIG_DIR"/*; do
        [[ -e "$item" ]] || continue
        name="$(basename "$item")"
        # Hammerspoon reads from ~/.hammerspoon, not ~/.config, so it's linked separately below.
        [[ "$name" == "hammerspoon" ]] && continue
        link_config "$item" "$HOME/.config/$name"
    done
fi

# Link Hammerspoon config (used by the visual window switcher, see skhdrc)
if [ "$IS_MACOS" = true ] && [[ -d "$REPO_CONFIG_DIR/hammerspoon" ]]; then
    link_config "$REPO_CONFIG_DIR/hammerspoon" "$HOME/.hammerspoon"
fi

# Link ~/.ai configuration directory
if [[ -d "$DOTFILES_DIR/ai" ]]; then
    link_config "$DOTFILES_DIR/ai" "$HOME/.ai"
    log_info "Synchronizing global AI settings across tools..."
    bash "$HOME/.ai/sync.sh"
fi

# Link VS Code and Cursor User settings & keybindings (Platform dependent)
if [ "$IS_MACOS" = true ]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
else
    VSCODE_USER_DIR="$HOME/.config/Code/User"
    CURSOR_USER_DIR="$HOME/.config/Cursor/User"
fi

if [[ -d "$DOTFILES_DIR/config/vscode" ]]; then
    log_info "Linking VS Code and Cursor configurations..."
    link_config "$DOTFILES_DIR/config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    link_config "$DOTFILES_DIR/config/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

    link_config "$DOTFILES_DIR/config/vscode/settings.json" "$CURSOR_USER_DIR/settings.json"
    link_config "$DOTFILES_DIR/config/vscode/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
fi

# Link Linux desktop application launchers
if [ "$IS_LINUX" = true ] && [[ -d "$DOTFILES_DIR/desktop_files" ]]; then
    log_info "Linking Linux desktop launchers..."
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    for item in "$DOTFILES_DIR/desktop_files"/*; do
        [[ -e "$item" ]] || continue
        name="$(basename "$item")"
        link_config "$item" "$DESKTOP_DIR/$name"
    done
fi

log_success "Dotfiles setup completed successfully on $OS!"
