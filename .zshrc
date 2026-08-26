# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh


# Homebrew (must be early so /opt/homebrew/bin shadows /usr/bin for python)
eval "$(/opt/homebrew/bin/brew shellenv)"

# PATH & env
export PATH=$PATH:/Users/shlokkohli/mongodb-macos-aarch64-7.0.8/bin

# Rust / Cargo
source "$HOME/.cargo/env"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# pipx
export PATH="$PATH:/Users/shlokkohli/.local/bin"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# bun
[ -s "/Users/shlok/.bun/_bun" ] && source "/Users/shlok/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/Library/PostgreSQL/17/bin:$PATH"

# Aliases
alias c="clear"
alias v="nvim"
alias lg="lazygit"
alias python="python3"
alias oc="opencode"

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# fzf
source <(fzf --zsh)

_accept_or_complete() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle autosuggest-accept
  else
    zle expand-or-complete
  fi
}
zle -N _accept_or_complete
bindkey '\t' _accept_or_complete


# opencode
export PATH=/Users/shlokkohli/.opencode/bin:$PATH

# Superfile cd-on-quit wrapper
source ~/.config/zsh/spf.zsh

# Added by Antigravity CLI installer
export PATH="/Users/shlokkohli/.local/bin:$PATH"
