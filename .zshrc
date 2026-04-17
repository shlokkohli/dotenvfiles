# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh


# PATH & env
export PATH=$PATH:/Users/shlok/mongodb-macos-aarch64-7.0.8/bin

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Antigravity
export PATH="/Users/shlok/.antigravity/antigravity/bin:$PATH"

# pipx
export PATH="$PATH:/Users/shlok/.local/bin"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# bun
[ -s "/Users/shlok/.bun/_bun" ] && source "/Users/shlok/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Aliases
alias c="clear"
alias v="nvim"

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# fzf
source <(fzf --zsh)

# Added by Antigravity
export PATH="/Users/shlok/.antigravity/antigravity/bin:$PATH"

# Tab to accept autosuggestion (if one exists), fallback to normal completion
# Must be LAST — fzf and other tools rebind Tab during their init
_accept_or_complete() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle autosuggest-accept
  else
    zle expand-or-complete
  fi
}
zle -N _accept_or_complete
bindkey '\t' _accept_or_complete
# Added by Antigravity
export PATH="/Users/shlok/.antigravity/antigravity/bin:$PATH"
