# Setup Guide — Fresh macOS (after reset)

> **For humans, no AI needed.** Follow this top-to-bottom after you erase/reset your Mac.
> The automated version of the same steps lives in `bootstrap.sh` (the "AI path") — you can ignore it for now or run `bash ~/dotfiles/bootstrap.sh` later if you get stuck and want everything installed at once.

---

## Table of Contents

- [What this gets you](#what-this-gets-you)
- [Where things live](#where-things-live)
- [Part A — Essentials (do these in order)](#part-a--essentials-do-these-in-order)
  - [1. Install Git (via Xcode Command Line Tools)](#1-install-git-via-xcode-command-line-tools)
  - [2. Clone this repo](#2-clone-this-repo)
  - [3. Install Homebrew](#3-install-homebrew)
  - [4. Install Oh My Zsh + the autosuggestions plugin](#4-install-oh-my-zsh--the-autosuggestions-plugin)
  - [5. Symlink your dotfiles with GNU Stow](#5-symlink-your-dotfiles-with-gnu-stow)
  - [6. Install Node via NVM](#6-install-node-via-nvm)
  - [7. Restart your terminal](#7-restart-your-terminal)
- [Part B — Optional (do later, or skip)](#part-b--optional-do-later-or-skip)
- [Troubleshooting](#troubleshooting)
- [Checklist](#checklist)

---

## What this gets you

After **Part A** (~10 minutes) you will have:

- `git` working
- This repo cloned to `~/dotfiles`
- `~/.zshrc` and `~/.zshenv` active (symlinked from the repo, so future `git pull` updates them)
- Configs for `nvim`, `ghostty`, `tmux`, `zsh` live (symlinked into `~/.config/...`)
- Node 24 + npm via NVM

Everything else (databases, Rust, Java, opencode, etc.) is in **Part B** or in `bootstrap.sh` + `Brewfile`. You can install those whenever you need them — the guide below still walks you through each one.

---

## Where things live

| What | Where on disk | How it got there |
|---|---|---|
| This repo | `~/dotfiles` | you `git clone` it (step 2) |
| Your shell config | `~/.zshrc` → `~/dotfiles/.zshrc` | symlink created by `stow` (step 5) |
| Env tweaks | `~/.zshenv` → `~/dotfiles/.zshenv` | same |
| App configs | `~/.config/nvim`, `ghostty`, `tmux`, `zsh` → `~/dotfiles/.config/...` | same |
| Oh My Zsh | `~/.oh-my-zsh` | installer (step 4) |
| Homebrew packages | `/opt/homebrew` | `brew bundle` |

**Important:** `stow` does not copy files — it creates **symlinks**. Editing `~/.zshrc` is the same as editing `~/dotfiles/.zshrc`. That's how a single `git pull` on any machine updates everything.

The repo's `.stowrc` tells stow to ignore `Brewfile`, `bootstrap.sh`, `nvim-setup.sh`, `Readme.md`, etc. — those stay inside `~/dotfiles` and are not symlinked into your home directory.

---

## Part A — Essentials (do these in order)

> Do not skip or reorder steps 4 and 5 — Oh My Zsh must be installed **before** you run `stow`. If you stow first, the Oh My Zsh installer will back up your freshly-symlinked `~/.zshrc` and replace it with a default one.

### 1. Install Git (via Xcode Command Line Tools)

A fresh macOS has no `git`. The simplest way to get it is through Apple's Command Line Tools.

1. Open **Terminal** (Spotlight → `Terminal` → Enter).

2. Run:

   ```bash
   xcode-select --install
   ```

   A system dialog pops up → click **Install** → agree to the license → wait for it to finish.

   > Alternative trigger: just run `git --version` — macOS will offer to install the tools. Same result.

3. Verify:

   ```bash
   git --version
   xcode-select -p
   ```

   Expected: something like `git version 2.4x` and a path like `/Library/Developer/CommandLineTools`.

---

### 2. Clone this repo

We use **HTTPS** here because your SSH keys don't exist yet on a fresh machine. (You'll set up SSH later in Part B if you want to switch back to `git@github-personal`.)

```bash
git clone https://github.com/shlokkohli/dotfiles.git ~/dotfiles
```

Verify:

```bash
ls ~/dotfiles
```

You should see `Brewfile`, `bootstrap.sh`, `.zshrc`, `.zshenv`, `.config/`, `SETUP.md`, etc.

> If you prefer SSH immediately: generate a key first (`ssh-keygen -t ed25519 -C "shlokkohli11@gmail.com"`), add it to GitHub → Settings → SSH keys, add the `github-personal` host block to `~/.ssh/config`, then `git clone git@github-personal:shlokkohli/dotfiles.git ~/dotfiles` instead.

---

### 3. Install Homebrew

Homebrew is the package manager that installs `stow`, `neovim`, `git-delta`, `fzf`, `zoxide`, and everything in `Brewfile`.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

When it finishes, it prints a **"Next steps"** line. Run it. On Apple Silicon it is usually:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

> To make it permanent now: that `eval` line will be added to your shell automatically once your dotfiles are symlinked (your `.zshrc` already handles brew's PATH), but running it once right now lets the next commands find `brew`.

Verify:

```bash
brew --version
which brew
```

---

### 4. Install Oh My Zsh + the autosuggestions plugin

Your `.zshrc` starts with `source $ZSH/oh-my-zsh.sh` and `plugins=(git zsh-autosuggestions)` — it will error without Oh My Zsh. Install it **before** stowing.

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

> The `"" --unattended` flag tells the Oh My Zsh installer not to change your shell or start a new session — it just drops files into `~/.oh-my-zsh`.

Verify:

```bash
ls ~/.oh-my-zsh
ls ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

---

### 5. Symlink your dotfiles with GNU Stow

**What `stow` does:** for every file in `~/dotfiles` (except the ones listed in `.stowrc`), it creates a symlink in your home directory. Example: `~/dotfiles/.zshrc` → `~/.zshrc`. Afterwards, editing either path edits the same file, and `git pull` inside `~/dotfiles` updates your live config.

```bash
brew install stow
```

```bash
cd ~/dotfiles
stow .
```

If `stow` complains about an existing file (e.g. `existing target is neither a link nor a directory: .zshrc`):

```bash
# Back up whatever was in the way, then try again
mv ~/.zshrc ~/.zshrc.bak        # replace .zshrc with the conflicting filename
stow .
```

`bootstrap.sh` does this backup automatically for `.zshrc`, `.zshenv`, `.config/nvim`, `.config/ghostty`, `.config/tmux` — but when you run `stow` manually, you do it yourself for whichever file the error names.

Verify:

```bash
ls -l ~/.zshrc ~/.zshenv
ls -l ~/.config/nvim ~/.config/ghostty ~/.config/tmux ~/.config/zsh 2>&1 | head -20
```

Every line should show `-> /Users/<you>/dotfiles/...` (a symlink). Example:

```
.zshrc -> dotfiles/.zshrc
```

If you see a symlink, you're done with dotfiles.

---

### 6. Install Node via NVM

Your `.zshrc` already knows about NVM (`export NVM_DIR="$HOME/.nvm"` + the two `source` lines) — you just need to put NVM and Node there.

**Install NVM:**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

Close and reopen Terminal once so the `NVM_DIR` lines from your freshly-symlinked `.zshrc` take effect. Or load it now without restarting:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Install Node 24 (the default this repo uses) and set it as the default:**

```bash
nvm install 24
nvm use 24
nvm alias default 24
```

Verify:

```bash
node -v   # expect v24.x.x
npm -v
nvm ls
```

**Global npm packages** (optional — install only what you still need):

```bash
npm install -g @nestjs/cli command-code corepack omniroute
```

> `bootstrap.sh` installs exactly these four. If you had extra globals on the old machine you still want, add them to the same line. To see what was on the old machine, the bootstrap installs: `@nestjs/cli`, `command-code`, `corepack`, `omniroute`.

Close and reopen Terminal again so every new shell starts on Node 24.

---

### 7. Restart your terminal

Either quit and reopen Terminal, or:

```bash
source ~/.zshrc
```

> It's normal to see a few "command not found" lines the first time you source `.zshrc` on a fresh machine (e.g. `zoxide`, `fzf`, `cargo`). They go away as you install those tools in Part B / `Brewfile`. The shell still works.

You now have a working shell with your dotfiles. Run a quick sanity check:

```bash
echo $ZSH              # should print /Users/<you>/.oh-my-zsh
alias | grep -E "^(c=|v=|lg=)"  # your aliases from .zshrc: c, v, lg
```

---

## Part B — Optional (do later, or skip)

Everything below is already covered by the one-liner at the bottom. Pick only what you need.

### B1. One-command full restore (the "AI path")

If you want *everything* at once — all Brewfile packages, Rust, Java 17, opencode, Neovim parsers — just run:

```bash
bash ~/dotfiles/bootstrap.sh
```

It's safe to run multiple times (every step checks "already installed? → skip"). The bootstrap does, in order: Xcode CLT → Homebrew → `brew bundle install` (everything in `Brewfile`) → Oh My Zsh → stow → NVM/Node 24 → Rust (rustup) → Java 17 shim → opencode → `nvim-setup.sh`.

### B2. Brewfile only (packages without the rest of bootstrap)

```bash
brew bundle install --file=~/dotfiles/Brewfile
```

What this installs (highlights): `neovim`, `tmux`, `fzf`, `ripgrep`, `fd`, `zoxide`, `starship`, `stow`, `lazygit`, `gh`, `git-delta`, `go`, `python@3.14`, `node`, `nvm`, `pipx`, `uv`, `yazi`, `glow`, `bat`, `superfile`, `fastfetch`, `ffmpeg`, `jq`, `cocoapods`, `pgloader`, `ruby`, `tectonic`, `mongodb-database-tools`, `bun`, plus casks `ghostty`, `kitty`, `anaconda`, `orbstack`, `temurin@17`, etc. See `Brewfile` for the full list.

### B3. Neovim — first-launch setup

```bash
nvim              # open once, let lazy.nvim install plugins, then :qa
bash ~/dotfiles/nvim-setup.sh   # compiles treesitter parsers + copies queries
```

Reopen `nvim` — syntax highlighting and LSP should work immediately.

### B4. SSH keys + GitHub hosts (to switch back to SSH remotes)

Your old `~/.ssh/config` had three hosts (`github-personal`, `github-office`, `gitlab`). On a fresh machine they don't exist.

1. Generate a key (if you didn't copy `~/.ssh` from a backup):

   ```bash
   ssh-keygen -t ed25519 -C "shlokkohli11@gmail.com" -f ~/.ssh/id_ed25519
   cat ~/.ssh/id_ed25519.pub   # copy this
   ```

   Repeat for the other keys (`id_ed25519_pixelwand`, `id_ed25519_gitlab`) if you need them.

2. Add each `.pub` to the right GitHub/GitLab account (Settings → SSH and GPG keys → New SSH key).

3. Recreate `~/.ssh/config`:

   ```
   # Personal GitHub
   Host github-personal
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519
     IdentitiesOnly yes

   # GitHub (Work -> Pixelwand)
   Host github-office
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519_pixelwand
     IdentitiesOnly yes

   # GitLab (Work -> Vitto)
   Host gitlab.com
     HostName gitlab.com
     User git
     IdentityFile ~/.ssh/id_ed25519_gitlab
     IdentitiesOnly yes
   ```

   If you use OrbStack, keep `Include ~/.orbstack/ssh/config` at the very top.

4. Switch this repo's remote back to SSH (optional):

   ```bash
   cd ~/dotfiles
   git remote set-url origin git@github-personal:shlokkohli/dotfiles.git
   git remote -v
   ```

5. Test:

   ```bash
   ssh -T git@github-personal
   ssh -T git@github-office
   ```

### B5. Git identity + delta pager

Your old global config:

```bash
git config --global user.name "Shlok Kohli"
git config --global user.email "shlokkohli11@gmail.com"
git config --global core.editor "nvim"
git config --global core.pager "delta"
git config --global interactive.difffilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
# ... plus the other delta decor settings — or just copy ~/.gitconfig from a backup
```

If you had a `~/.gitignore_global` and the `~/.gitconfig-pixelwand` include, copy those files from backup too.

### B6. Individual tools (if you skipped the full bootstrap)

```bash
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
source "$HOME/.cargo/env"

# Java 17 — installed via Brewfile cask temurin@17
# .zshrc already sets JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
# bootstrap.sh creates a symlink temurin-17.jdk -> jdk-17.jdk so it keeps working.
# If you installed manually, run: sudo ln -s /Library/Java/JavaVirtualMachines/temurin-17.jdk /Library/Java/JavaVirtualMachines/jdk-17.jdk

# opencode
curl -fsSL https://opencode.ai/install | bash

# bun — installed via Brewfile (brew install bun). Verify:
bun --version
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `stow: existing target is neither a link nor a directory: .zshrc` | `mv ~/.zshrc ~/.zshrc.bak && stow .` (repeat for whichever file it names) |
| After `stow .`, `source ~/.zshrc` says `~/.oh-my-zsh not found` | You stowed before installing Oh My Zsh. Install Oh My Zsh first (step 4), then re-run `cd ~/dotfiles && stow . --restow` |
| `brew: command not found` after installing Homebrew | Run the `eval "$(/opt/homebrew/bin/brew shellenv)"` line Homebrew printed, then `source ~/.zshrc` |
| `nvm: command not found` | `export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"` — then retry `nvm install 24` |
| `source ~/.zshrc` prints `cargo env: no such file` / `zoxide: command not found` / `fzf: command not found` | Normal on a fresh machine. Those tools come from `Brewfile` / `bootstrap.sh`. Install them or ignore until you need them. |
| `git clone` over HTTPS asks for a password | Use a Personal Access Token (PAT) as the password, or switch to SSH after you set up keys (Part B4) |
| `JAVA_HOME` points to `jdk-17.jdk` but `temurin-17.jdk` is installed | `sudo ln -s /Library/Java/JavaVirtualMachines/temurin-17.jdk /Library/Java/JavaVirtualMachines/jdk-17.jdk` |
| Symlinks look wrong (`ls -l ~/.config/...` shows a real directory, not `->`) | You had a real directory there before stowing. `mv ~/.config/nvim ~/.config/nvim.bak && cd ~/dotfiles && stow .` |
| Want to undo stow | `cd ~/dotfiles && stow -D .` removes all the symlinks |

---

## Checklist

Copy this into a note and tick as you go:

```
[ ] 1. xcode-select --install  →  git --version works
[ ] 2. git clone https://github.com/shlokkohli/dotfiles.git ~/dotfiles
[ ] 3. Install Homebrew  →  brew --version works
[ ] 4. Oh My Zsh + zsh-autosuggestions  →  ls ~/.oh-my-zsh
[ ] 5. brew install stow  →  cd ~/dotfiles && stow .  →  ls -l ~/.zshrc shows ->
[ ] 6. NVM + Node 24  →  node -v shows v24
[ ] 7. source ~/.zshrc or reopen Terminal  →  prompt looks normal
[ ] (optional) bash ~/dotfiles/bootstrap.sh  for everything else
[ ] (optional) SSH keys + git config  →  ssh -T git@github-personal works
```

---

*If you get stuck at any step, run `bash ~/dotfiles/bootstrap.sh` — it does all of Part A + most of Part B automatically and is safe to run even after you've done some steps by hand.*
