# dotfiles

My personal configuration files for macOS and Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

> **OS Support**: macOS and Linux only. This setup will not work on Windows.

---

## What is this?

This repo holds all my shell, editor, and terminal configs in one place. Instead of having config files scattered around the home directory with no version control, everything lives here inside `~/dotfiles`. The actual files your system reads are just symlinks — shortcuts that point back into this folder.

So when your terminal opens and reads `~/.zshrc`, it follows a pointer to `~/dotfiles/.zshrc`. Same file, one copy on disk. Edit it anywhere and the change is immediately reflected everywhere.

---

## What's inside

```
dotfiles/
├── .zshrc               # Zsh shell config (Oh-My-Zsh + Powerlevel10k)
├── .zshenv              # Environment variables loaded before everything else
├── .gitignore           # Whitelist — only tracked files are intentional
└── .config/
    ├── nvim/            # Neovim configuration
    ├── ghostty/         # Ghostty terminal configuration
    ├── tmux/            # Tmux configuration
    └── zed/             # Zed editor configuration
```

---

## How it works

GNU Stow reads the folder structure inside `~/dotfiles` and creates matching symlinks in your home directory. The structure mirrors exactly where each file needs to live under `~`.

For example:

| Real file (in this repo)         | Symlink (what the system sees)  |
|----------------------------------|---------------------------------|
| `~/dotfiles/.zshrc`              | `~/.zshrc`                      |
| `~/dotfiles/.zshenv`             | `~/.zshenv`                     |
| `~/dotfiles/.config/nvim/`       | `~/.config/nvim/`               |
| `~/dotfiles/.config/ghostty/`    | `~/.config/ghostty/`            |
| `~/dotfiles/.config/tmux/`       | `~/.config/tmux/`               |
| `~/dotfiles/.config/zed/`        | `~/.config/zed/`                |

Every tool still finds its config at the hardcoded path it expects. Nothing breaks. But every edit is happening inside a git repo.

---

## Setting up on a new machine

### 1. Install dependencies

**macOS**
```bash
brew install stow
```

**Linux (Debian/Ubuntu)**
```bash
sudo apt install stow
```

### 2. Clone the repo

```bash
git clone git@github.com:shlokkohli/dotfiles.git ~/dotfiles
```

### 3. Create symlinks

```bash
cd ~/dotfiles
stow .
```

That's it. Stow will wire everything up. Your shell, Neovim, Tmux, and Ghostty will all pick up the configs immediately.

If you get a conflict error, it means a config file already exists at the target location. Back it up and re-run:

```bash
mv ~/.zshrc ~/.zshrc.bak
stow .
```

---

## Adding a new config to the repo

Say you install a new tool and want to track its config. The pattern is always the same:

1. Move the config into `~/dotfiles`, keeping the exact same folder structure it had under `~`
2. Add it to `.gitignore` so it gets tracked
3. Re-run `stow .` to create the symlink
4. Commit

For example, adding a new tool whose config lives at `~/.config/newtool/`:

```bash
mv ~/.config/newtool ~/dotfiles/.config/newtool
# add !.config/newtool/** to .gitignore
cd ~/dotfiles
stow .
git add .
git commit -m "feat: add newtool config"
```

---

## Why not just keep .git in the home directory?

The home directory is full of things you never want in a git repo — SSH keys, credentials, `node_modules`, tool caches, and hundreds of app-specific files. Putting `.git` directly in `~` means one accidental `git add .` could stage all of it.

The `~/dotfiles` approach keeps the repo isolated. The `.gitignore` in this repo uses a whitelist strategy — it ignores everything by default and only tracks files you explicitly name. Nothing gets in by accident.

---

## Why not use a bare git repo?

A bare repo approach (sometimes called the `--bare` method) skips Stow but requires you to set a custom `GIT_DIR` and `GIT_WORK_TREE` environment variable, and use a special alias instead of `git` for all operations. It also makes it harder to see what's tracked vs untracked at a glance.

Stow is simpler. The folder structure is self-documenting, symlinks are easy to inspect with `ls -la`, and you use plain `git` commands with no tricks.

---

## Environment

- **Shell**: Zsh with [Oh-My-Zsh](https://ohmyz.sh) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Editor**: [Neovim](https://neovim.io)
- **Terminal**: [Ghostty](https://ghostty.org)
- **Multiplexer**: [Tmux](https://github.com/tmux/tmux)
- **Dotfile manager**: [GNU Stow](https://www.gnu.org/software/stow/)
