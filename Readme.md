# dotfiles

My personal config files managed with GNU Stow.

Works on **macOS and Linux only**. Does not work on Windows.

---

## Setting up on a new machine

### macOS (Automatic Setup)

To fully automate the setup of a new or reset macOS machine, we provide a bootstrap script. It installs Xcode Command Line Tools, Homebrew (restoring all packages, casks, and VS Code extensions defined in the `Brewfile`), Oh My Zsh with custom plugins, GNU Stow, NVM with Node v22, and symlinks all your dotfiles automatically.

1. **Clone this repo** into your home directory as `dotfiles`:
   ```bash
   git clone git@github.com:shlokkohli/dotfiles.git ~/dotfiles
   ```

2. **Run the bootstrap script**:
   ```bash
   bash ~/dotfiles/bootstrap.sh
   ```

3. **Restart your terminal** or run `source ~/.zshrc` to activate the configuration!

---

### Manual Setup (or Linux)

If you prefer to set up manually or are on a Linux machine:

1. **Install GNU Stow**:
   - **macOS**: `brew install stow`
   - **Linux (Debian/Ubuntu)**: `sudo apt install stow`

2. **Clone this repo** into your home directory as `dotfiles`:
   ```bash
   git clone git@github.com:shlokkohli/dotfiles.git ~/dotfiles
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
