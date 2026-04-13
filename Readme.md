# dotfiles

My personal config files managed with GNU Stow.

Works on **macOS and Linux only**. Does not work on Windows.

---

## Setting up on a new machine

### 1. Install GNU Stow

This is the only tool you need to install.

**macOS**
```bash
brew install stow
```

**Linux (Debian/Ubuntu)**
```bash
sudo apt install stow
```

### 2. Clone this repo

Always clone it into your home directory as `dotfiles`. The folder name and location matter.

```bash
git clone git@github.com:shlokkohli/dotfiles.git ~/dotfiles
```

### 3. Run Stow

This one command creates all the symlinks. It reads everything inside `~/dotfiles` and wires it up to the right places in your home directory.

```bash
cd ~/dotfiles
stow .
```

That's it. Your shell, Neovim, Tmux, and Ghostty configs are all active.

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
