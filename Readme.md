# dotfiles

My personal config files managed with GNU Stow.

Works on **macOS and Linux only**. Does not work on Windows.

---

## Which guide do I follow?

| Situation | What to read |
|---|---|
| **Fresh / reset Mac, doing it by hand** | **[SETUP.md](SETUP.md)** — step-by-step, no AI needed (git → clone → symlink → node) |
| **Want everything automated at once** | `bash ~/dotfiles/bootstrap.sh` — one-liner, installs everything (see below) |

---

## Quick start (automated)

The bootstrap script installs Xcode Command Line Tools, Homebrew + everything in `Brewfile`, Oh My Zsh + `zsh-autosuggestions`, GNU Stow symlinks, NVM + Node 24 (+ global npm packages), Rust via rustup, Java 17, opencode, and runs the Neovim setup. It's safe to re-run.

```bash
git clone https://github.com/shlokkohli/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

Restart your terminal or run `source ~/.zshrc`.

> Detailed manual steps with explanations of every command are in **[SETUP.md](SETUP.md)**. If you get stuck at any point, that file has you covered.

---

## Manual Setup (or Linux)

If you prefer to set up by hand or are on Linux:

1. **Install GNU Stow**:
   - **macOS**: `brew install stow`
   - **Linux (Debian/Ubuntu)**: `sudo apt install stow`

2. **Clone this repo** into your home directory as `dotfiles`:
   ```bash
   git clone https://github.com/shlokkohli/dotfiles.git ~/dotfiles
   ```

3. **Symlink dotfiles**:
   ```bash
   cd ~/dotfiles
   stow .
   ```

4. **Set up Neovim (colors + LSP)**:
   Open Neovim once and let lazy.nvim finish installing plugins, then close it and run:
   ```bash
   bash ~/dotfiles/nvim-setup.sh
   ```

This compiles all treesitter parsers and copies query files so syntax highlighting works immediately. LSP servers (gopls, rust_analyzer, etc.) auto-install via Mason the first time you open a file of that type.

---

## If Stow gives you a conflict error

It means a config file already exists at the target location from before. Just back it up and run stow again.

```bash
# example — do this for whichever file is conflicting
mv ~/.zshrc ~/.zshrc.bak

stow .
```

---

## Adding a new config to the repo in the future

Whenever you install a new tool and want its config tracked here, follow this pattern:

```bash
# 1. move the config into dotfiles, keeping the same folder structure
mv ~/.config/newtool ~/dotfiles/.config/newtool

# 2. whitelist it in .gitignore by adding:
#    !.config/newtool/
#    !.config/newtool/**

# 3. re-run stow to create the symlink
cd ~/dotfiles
stow .

# 4. commit it
git add .
git commit -m "feat: add newtool config"
git push
```
