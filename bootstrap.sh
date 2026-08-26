#!/bin/bash
# -----------------------------------------------------------------------------
# macOS Dotfiles & System Setup Bootstrap Script
# -----------------------------------------------------------------------------
# This script automates setting up a new or reset macOS machine. It installs:
#   1. Xcode Command Line Tools
#   2. Homebrew (and all Brewfile taps, brews, casks)
#   3. Oh My Zsh & zsh-autosuggestions
#   4. GNU Stow (to symlink all dotfiles safely)
#   5. NVM (Node Version Manager) & Node v24 + global packages
#   6. Rust via rustup
#   7. Java 17 compat shim (so existing JAVA_HOME keeps working with temurin)
#   8. opencode
#   9. Neovim post-setup (treesitter parsers + queries)
#
# This is the COMPREHENSIVE / AI path. For the minimal human-readable guide
# (git -> clone -> symlink -> node), see SETUP.md.
#
# Usage: bash ~/dotfiles/bootstrap.sh
# Safe to re-run — every step is idempotent.
# -----------------------------------------------------------------------------

set -e

# --- Colors for Output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}==>${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; echo "Aborting."; exit 1; }

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    fail "This bootstrap script only supports macOS."
fi

echo -e "${GREEN}"
echo "    ____              __       __                       "
echo "   / __ )____  ____  / /______/ /__________ _____  ____ "
echo "  / __  / __ \/ __ \/ __/ ___/ __/ ___/ __ \`/ __ \/ __ \\"
echo " / /_/ / /_/ / /_/ / /_(__  ) /_/ /  / /_/ / /_/ / /_/ /"
echo "/_____/\____/\____/\__/____/\__/_/   \__,_/ .___/ .___/ "
echo "                                         /_/   /_/      "
echo -e "${NC}"
info "Starting macOS System Bootstrap..."

# --- Step 1: Xcode Command Line Tools ---
info "Step 1: Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools. Please follow the prompt..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    ok "Xcode Command Line Tools installed."
else
    ok "Xcode Command Line Tools are already installed."
fi

# --- Step 2: Homebrew ---
info "Step 2: Checking Homebrew..."
if ! command -v brew &>/dev/null && [ ! -f "/opt/homebrew/bin/brew" ] && [ ! -f "/usr/local/bin/brew" ]; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    ok "Homebrew is already installed."
fi

# Dynamically set up Homebrew environment for this session
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    fail "Homebrew was not found in PATH after installation."
fi

# --- Step 3: Brew Bundle ---
info "Step 3: Restoring packages from Brewfile..."
BREWFILE_PATH="$HOME/dotfiles/Brewfile"
if [ -f "$BREWFILE_PATH" ]; then
    brew bundle install --file="$BREWFILE_PATH"
    ok "Brewfile packages successfully installed."
else
    fail "Brewfile not found at $BREWFILE_PATH"
fi

# --- Step 4: Oh My Zsh & Plugins ---
info "Step 4: Setting up Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh (unattended)..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed."
else
    ok "Oh My Zsh is already installed."
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions installed."
else
    ok "zsh-autosuggestions plugin is already installed."
fi

# --- Step 5: Symlinking Dotfiles with Stow ---
info "Step 5: Symlinking dotfiles..."

# Helper function to safely back up existing configs before stowing
backup_if_exists() {
    local target="$HOME/$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            # If it's a symlink, verify if it points to dotfiles directory.
            local link_dest
            link_dest=$(readlink "$target")
            if [[ "$link_dest" != *"/dotfiles/"* ]]; then
                warn "Removing foreign symlink: $target (pointing to $link_dest)"
                rm "$target"
            fi
        else
            warn "Backing up conflicting resource: $target -> $target.bak"
            mv "$target" "$target.bak"
        fi
    fi
}

# Ensure .config folder exists
mkdir -p "$HOME/.config"

# Safe backups of key dotfiles/directories before Stow runs
backup_files=(
    ".zshrc"
    ".zshenv"
    ".config/nvim"
    ".config/ghostty"
    ".config/tmux"
)

for file in "${backup_files[@]}"; do
    backup_if_exists "$file"
done

cd "$HOME/dotfiles"
stow .
ok "Dotfiles successfully symlinked."

# --- Step 6: Node & NVM Setup ---
info "Step 6: Setting up NVM & Node..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    info "Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "NVM installed."
else
    ok "NVM is already installed."
fi

# Load NVM for the rest of this session
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm &>/dev/null; then
    info "Installing Node v24 and setting as default..."
    nvm install 24
    nvm use 24
    nvm alias default 24
    ok "Node v24 installed and set as default."

    info "Installing global NPM packages (@nestjs/cli, command-code, corepack, omniroute)..."
    npm install -g @nestjs/cli command-code corepack omniroute
    ok "Global npm packages installed."
else
    warn "NVM command not found. Skipping Node and global npm installation."
fi

# --- Step 7: Rust via rustup ---
info "Step 7: Setting up Rust (rustup)..."
if ! command -v rustup &>/dev/null && [ ! -f "$HOME/.cargo/bin/rustup" ]; then
    info "Installing rustup (default stable toolchain)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    ok "rustup installed."
else
    ok "rustup is already installed."
fi
# Source cargo env for this session so cargo/rustc are available
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
if command -v rustc &>/dev/null; then
    ok "Rust $(rustc --version) ready."
else
    warn "Rust not found in PATH after install — open a new terminal and it will be available."
fi

# --- Step 8: Java 17 compat shim ---
info "Step 8: Checking Java 17 shim..."
# Brew cask temurin@17 installs to .../temurin-17.jdk but .zshrc points to .../jdk-17.jdk.
# Create a symlink so the existing JAVA_HOME keeps working.
if [ -d "/Library/Java/JavaVirtualMachines/temurin-17.jdk" ] && [ ! -e "/Library/Java/JavaVirtualMachines/jdk-17.jdk" ]; then
    info "Creating jdk-17.jdk symlink -> temurin-17.jdk..."
    sudo ln -s "/Library/Java/JavaVirtualMachines/temurin-17.jdk" "/Library/Java/JavaVirtualMachines/jdk-17.jdk"
    ok "Java shim created."
else
    ok "Java shim already in place or not needed."
fi

# --- Step 9: opencode ---
info "Step 9: Setting up opencode..."
if ! command -v opencode &>/dev/null && [ ! -f "$HOME/.opencode/bin/opencode" ]; then
    info "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash
    ok "opencode installed."
else
    ok "opencode is already installed."
fi
# Ensure opencode is on PATH for this session
if [ -f "$HOME/.opencode/bin/opencode" ]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi

# --- Step 10: Neovim Post-Setup ---
info "Step 10: Setting up Neovim (compiling treesitter and plugins)..."
if [ -f "$HOME/dotfiles/nvim-setup.sh" ]; then
    bash "$HOME/dotfiles/nvim-setup.sh"
    ok "Neovim setup complete."
else
    warn "nvim-setup.sh not found. Skipping Neovim post-setup."
fi

# --- Done ---
echo -e "${GREEN}"
ok "System Setup Completed successfully!"
echo "Please restart your terminal or run: source ~/.zshrc"
echo -e "${NC}"
