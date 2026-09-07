# ~/.zinit-plugins.zsh — zsh plugin manager + plugin declarations
# Replaces antigen (unmaintained) with zinit (fast, turbo/lazy-loading).
# Sourced from ~/.zshrc. Safe to re-run: installs zinit on first run only.

# --- bootstrap: install zinit if missing ---
ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/share/zinit/zinit.git}"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}zinit%F{220}…%f"
  command mkdir -p "$(dirname "$ZINIT_HOME")"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
    print -P "%F{33}▓▒░ %F{34}zinit installed.%f" || \
    print -P "%F{160}▓▒░ zinit clone failed.%f"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# --- oh-my-zsh library snippets (needed by the OMZ plugins below) ---
zinit snippet OMZL::git.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::key-bindings.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::clipboard.zsh

# --- oh-my-zsh plugins (1:1 swap for the old antigen bundle list) ---
zinit snippet OMZP::git
zinit snippet OMZP::heroku
zinit snippet OMZP::pip
zinit snippet OMZP::command-not-found
zinit snippet OMZP::sudo
zinit snippet OMZP::docker
zinit snippet OMZP::helm
zinit snippet OMZP::kubectl
zinit snippet OMZP::globalias
zinit snippet OMZP::terraform
zinit snippet OMZP::tldr
zinit snippet OMZP::uv
zinit snippet OMZP::vscode
zinit snippet OMZP::autojump
zinit snippet OMZP::zsh-interactive-cd
zinit snippet OMZP::aliases
zinit snippet OMZP::argocd
zinit snippet OMZP::autoenv
zinit snippet OMZP::aws
zinit snippet OMZP::common-aliases
zinit snippet OMZP::cp
zinit snippet OMZP::docker-compose
zinit snippet OMZP::extract
zinit snippet OMZP::eza
zinit snippet OMZP::fzf
zinit snippet OMZP::dnf

# --- turbo mode: syntax highlighting, autosuggestions, extra completions ---
# `wait lucid` defers loading until after the prompt draws — this is the
# whole reason zinit is faster than antigen at shell startup.
zinit wait lucid for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# zoxide has its own init hook; no OMZ plugin needed
zinit wait lucid atload'eval "$(zoxide init zsh)"' for zdharma-continuum/null
