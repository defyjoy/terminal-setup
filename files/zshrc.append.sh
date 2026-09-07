export PATH=$PATH:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin
[ -s "$HOME/.autoenv/activate.sh" ] && source ~/.autoenv/activate.sh

zstyle ':omz:plugins:eza' 'show-group' no
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'header' no
zstyle ':omz:plugins:eza' 'time-style' 'default'
zstyle ':omz:plugins:eza' 'hyperlink' no
zstyle ':omz:plugins:eza' 'color-scale' age

# Plugin manager: zinit (see zinit-plugins.zsh in this same directory)
source ~/.zinit-plugins.zsh

alias k="kubecolor"
alias t="terragrunt"
alias tsc="terragrunt stack clean"
alias tsp="terragrunt stack run plan"
alias tsg="terragrunt stack generate"
alias tsa="terragrunt stack run apply --non-interactive"

# ============================================================
# BEAUTIFY-TERMINAL-BEGIN — roll back with ~/.terminal-rollback.sh
# ============================================================
# Starship prompt (draws the actual prompt; zinit/oh-my-zsh plugins above
# only provide completions/aliases/highlighting, not the prompt itself)
source <(starship init zsh)
# bat instead of cat
alias cat="bat"
# atuin: better history. Use: ctrl+r (atuin) | atuin search | atuin -f <dir>
eval "$(atuin init zsh)"
# True color for tmux / terminal apps
export COLORTERM=truecolor
# ============================================================
# BEAUTIFY-TERMINAL-END
# ============================================================

# git-use: switch active GitHub SSH identity
alias gu='git-use'
