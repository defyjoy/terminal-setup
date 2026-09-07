# Terminal Environment Runbook

Purpose: reproduce the exact look, feel, and behavior of my terminal setup on
any fresh macOS or Linux machine. This doc is written so an AI agent (or a
human) can follow it top to bottom with no other context and end up with a
functionally identical shell.

Source machine: macOS (Apple Silicon), iTerm2, zsh, zinit (zsh plugin
manager, pulling individual oh-my-zsh plugin/library files as snippets —
no local oh-my-zsh checkout required), starship prompt, atuin history,
tmux. Captured 2026-09-06, updated 2026-09-07 (migrated plugin manager
from antigen to zinit — antigen is unmaintained; zinit's turbo/lazy-load
mode defers plugin loading until after the prompt renders, so shell
startup stays fast regardless of plugin count).

Companion files (in this same directory, `files/`):
- `starship.toml` — prompt config, copy verbatim
- `tmux.conf` — tmux config, copy verbatim
- `zshrc.append.sh` — the block to append to `~/.zshrc`, copy verbatim
- `zinit-plugins.zsh` — plugin manager bootstrap + plugin list, copy to
  `~/.zinit-plugins.zsh` verbatim (sourced from `zshrc.append.sh`)
- `git-use` — custom bash script (GitHub SSH identity switcher), copy verbatim

---

## 0. Read this first — execution order matters

Do the steps in this exact order. Shell config assumes the binaries exist
before `~/.zshrc` is sourced. Do NOT open a new shell tab until Section 6
tells you to.

1. Install package manager (Homebrew on macOS / native pkg manager on Linux)
2. Install CLI tools (§2)
3. Install a Nerd Font + set the terminal emulator to use it (§3)
4. Make zsh the default shell (§4) — no oh-my-zsh install needed; zinit
   fetches the individual oh-my-zsh files it needs on first run
5. Write config files: `.zshrc`, `.zinit-plugins.zsh`, `.tmux.conf`,
   `starship.toml`, `git-use` (§5)
6. Reload shell and verify (§6) — first reload will be slower than normal
   (zinit clones itself + all plugins one time); every reload after that
   is fast

---

## 1. Platform detection

Run this first and branch accordingly for every step below:

```bash
case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) echo "Unsupported platform: $(uname -s)"; exit 1 ;;
esac
echo "Platform: $PLATFORM"
```

---

## 2. Package manager + CLI tools

### 2.1 macOS — install Homebrew if missing

```bash
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
```

Add to `~/.zprofile` (idempotent, check before appending):

```bash
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

### 2.2 Linux — package manager detection

Detect distro family and use the matching installer:

```bash
if command -v apt >/dev/null; then PKG=apt
elif command -v dnf >/dev/null; then PKG=dnf
elif command -v pacman >/dev/null; then PKG=pacman
else echo "No known package manager found"; exit 1
fi
```

Many of the tools below aren't in default distro repos at current versions —
prefer each tool's official install script/binary release over stale distro
packages, to match versions as closely as possible to the table below.

### 2.3 Tool inventory (install all of these)

| Tool | Purpose | Version on source machine | macOS (brew) | Linux |
|---|---|---|---|---|
| `zsh` | shell | 5.9 | preinstalled | `apt install zsh` / `dnf install zsh` / `pacman -S zsh` |
| `git` | vcs | 2.55.0 | `brew install git` | pkg manager or https://git-scm.com |
| `tmux` | terminal multiplexer | 3.7b | `brew install tmux` | pkg manager |
| `starship` | shell prompt | 1.26.0 | `brew install starship` | `curl -sS https://starship.rs/install.sh \| sh` |
| `atuin` | shell history (magic ctrl+r) | 18.21.0 | `brew install atuin` | `curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh \| sh` |
| `bat` | `cat` replacement w/ syntax highlighting | 0.26.1 | `brew install bat` | `apt install bat` (binary may be named `batcat`; symlink to `bat`) |
| `eza` | `ls` replacement | latest | `brew install eza` | see https://github.com/eza-community/eza/releases |
| `fzf` | fuzzy finder | 0.74.0 | `brew install fzf` | `apt install fzf` or https://github.com/junegunn/fzf#installation |
| `zoxide` | smarter `cd` | 0.10.0 | `brew install zoxide` | `curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \| bash` |
| `autojump` | directory jumping | latest | `brew install autojump` | `apt install autojump` |
| `kubecolor` | colorized kubectl output | latest | `brew install kubecolor/tap/kubecolor` | https://github.com/kubecolor/kubecolor#installation |
| `gh` | GitHub CLI (used by git credential helper) | latest | `brew install gh` | https://github.com/cli/cli#installation |
| `nvm` | node version manager | latest | `brew install nvm` | https://github.com/nvm-sh/nvm#installing-and-updating |
| `go` | Go toolchain | 1.26.5 | `brew install go` | pkg manager or https://go.dev/dl |

Install (macOS, one shot):

```bash
brew install git tmux starship atuin bat eza fzf zoxide autojump gh nvm go
brew install kubecolor/tap/kubecolor
```

Install (Linux, apt-based, approximate — some via official install scripts):

```bash
sudo apt update
sudo apt install -y zsh git tmux fzf autojump curl
curl -sS https://starship.rs/install.sh | sh
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
sudo apt install -y bat && sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
curl -sS https://webi.sh/eza | sh   # or grab a release binary
curl -sS https://raw.githubusercontent.com/cli/cli/trunk/install.sh 2>/dev/null || true  # or apt/GitHub release for `gh`
# kubecolor: grab a release binary from https://github.com/kubecolor/kubecolor/releases
```

Optional, only if this machine also needs Kubernetes/Terraform/cloud tooling
that the oh-my-zsh plugin list references (`kubectl`, `helm`, `terraform`,
`aws`, `argocd`) — install these only if actually used day to day:

```bash
brew install kubectl helm terraform awscli argocd
```

---

## 3. Font — Nerd Font (required for prompt icons + eza icons to render)

The source terminal profile uses two different Nerd Fonts:
- **Normal font**: Comic Shanns Mono Nerd Font, size 15
- **Non-ASCII font**: Arimo Nerd Font Propo, size 14

```bash
# macOS
brew install --cask font-comic-shanns-mono-nerd-font font-arimo-nerd-font

# Linux — no cask; download + install manually
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/ComicShannsMono.zip \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/ComicShannsMono.zip"
curl -Lo /tmp/Arimo.zip \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Arimo.zip"
unzip -o /tmp/ComicShannsMono.zip -d ~/.local/share/fonts
unzip -o /tmp/Arimo.zip -d ~/.local/share/fonts
fc-cache -fv
```

If you'd rather use a single simpler font everywhere (equally valid, just a
different look), **JetBrains Mono Nerd Font** is a good substitute and is
already common on the source machine too:

```bash
brew install --cask font-jetbrains-mono-nerd-font   # macOS
# Linux: nerd-fonts release ZIP "JetBrainsMono.zip", same unzip steps as above
```

### Terminal emulator config

- **macOS / iTerm2**: Preferences → Profiles → Text →
  - Font: `ComicShannsMonoNF-Regular`, size 15
  - Check "Use a different font for non-ASCII text" → `ArimoNFP-Regular`, size 14
  - Preferences → Profiles → Terminal → check "Unlimited scrollback"
  - Preferences → Profiles → Terminal → "Silence bell" left unchecked (bell audible)
- **Linux / GNOME Terminal, Kitty, Alacritty, etc.**: set the font to the
  same Nerd Font family in that app's preferences/config file. Non-ASCII
  fallback fonts are an iTerm-specific feature; on Linux terminals a single
  Nerd Font (e.g. Comic Shanns Mono NF, or JetBrains Mono NF as fallback)
  covers both cases fine.
- **True color**: ensure `COLORTERM=truecolor` is exported (already handled
  in the zshrc block in §5) and your terminal emulator has 24-bit color
  enabled (default on iTerm2, Kitty, Alacritty, WezTerm; GNOME Terminal
  supports it by default too).

---

## 4. Default shell

No oh-my-zsh install and no plugin-manager bootstrap needed here — that
happens automatically the first time `~/.zshrc` sources
`~/.zinit-plugins.zsh` (§5.1/§5.4). Just make sure zsh is the login shell:

```bash
chsh -s "$(command -v zsh)"
```

(zinit itself, and every plugin below, is a git clone — only `git` and
network access are required, no separate installer script.)

---

## 5. Write the config files

### 5.1 `~/.zshrc`

Append the contents of `files/zshrc.append.sh` (in this directory) to
`~/.zshrc`. This is a standalone `~/.zshrc` — no oh-my-zsh bootstrap lines
needed above it (see §5.4 for why).

```bash
cat files/zshrc.append.sh >> ~/.zshrc
```

Key things this block does (for context, not to be re-typed):
- Configures `eza` (zstyle settings consumed by the `eza` oh-my-zsh plugin,
  loaded via zinit in §5.4) to show icons, put directories first, and show
  git status in listings.
- Sources `~/.zinit-plugins.zsh` (§5.4) — this is what gives tab-completion,
  syntax highlighting-as-you-type, and inline autosuggestions.
- Sources `starship init zsh` — this is what actually draws the prompt
  (independent of any oh-my-zsh theme; there isn't one anymore).
- Aliases `cat` → `bat`.
- Sources `atuin init zsh` — replaces default shell history with atuin's
  fuzzy-searchable, timestamped, cross-session history (bound to Ctrl+R).
- Exports `COLORTERM=truecolor`.
- Aliases: `k` → `kubecolor`, `t` → `terragrunt` (+ `tsc`/`tsp`/`tsg`/`tsa`
  terragrunt-stack shortcuts), `gu` → `git-use`. Drop the terragrunt/k8s
  aliases if this machine doesn't do that kind of infra work.

### 5.2 `~/.tmux.conf`

```bash
cp files/tmux.conf ~/.tmux.conf
```

Gives: mouse support, true-color passthrough, 50k line history, vim-style
pane navigation (`prefix h/j/k/l`), `|`/`-` splits that preserve cwd, and a
dark status bar (`#111827` bg) with green `❯ session-name` on the left and
clock on the right.

### 5.3 `~/.config/starship.toml`

```bash
mkdir -p ~/.config
cp files/starship.toml ~/.config/starship.toml
```

Gives: no blank line before prompt, green/red `❯` for success/error, git
branch + minimal git status glyphs, command duration shown only for
commands over 3s, cyan truncated directory path (3 segments, stops at repo
root), and language version icons for node/python/terraform/go/package.json.

### 5.4 `~/.zinit-plugins.zsh` — plugin manager

```bash
cp files/zinit-plugins.zsh ~/.zinit-plugins.zsh
```

Sourced from `~/.zshrc` (§5.1). On the very first shell start after this
file exists, it:
1. `git clone`s zinit itself into `~/.local/share/zinit/zinit.git`
2. Pulls the individual oh-my-zsh library files it needs
   (`OMZL::git.zsh`, `OMZL::completion.zsh`, `OMZL::key-bindings.zsh`,
   `OMZL::directories.zsh`, `OMZL::clipboard.zsh`) as standalone snippets —
   no full oh-my-zsh checkout required
3. Pulls each oh-my-zsh plugin the same way (`OMZP::git`, `OMZP::docker`,
   `OMZP::kubectl`, `OMZP::terraform`, `OMZP::aws`, `OMZP::eza`,
   `OMZP::fzf`, etc. — full list is the same set the old antigen bundle
   used, minus `lein` and `zsh-navigation-tools`, which weren't actually
   installed on the source machine, and `themes`, which is moot once
   starship owns the prompt)
4. Loads `zsh-users/zsh-autosuggestions`, `zsh-users/zsh-completions`, and
   `zdharma-continuum/fast-syntax-highlighting` (a maintained fork of
   `zsh-syntax-highlighting`) in **turbo mode** (`wait lucid`) — these
   defer until just after the prompt first renders, which is the reason
   this setup starts faster than the old antigen one despite loading the
   same plugins
5. Hooks `zoxide init zsh` into the same turbo-mode block

This first run downloads ~5 git repos and will visibly pause for a few
seconds — that's expected and one-time only. Every shell start after that
reads from local disk and is fast.

If you ever want to add/remove a plugin: edit this file directly (it's not
generated), then `exec zsh`. To force-refresh all zinit plugins:
`zinit self-update && zinit update --all`.

### 5.5 `git-use` — GitHub SSH identity switcher

A custom tool (not a public package) that switches which SSH key is used
for `git@github.com` by re-pointing a symlink, based on named `Host` blocks
in `~/.ssh/config`.

```bash
mkdir -p ~/.local/bin
cp files/git-use ~/.local/bin/git-use
chmod +x ~/.local/bin/git-use
```

`~/.local/bin` is already added to `PATH` by the zshrc block in §5.1.

This tool is **optional** — only set it up if you actually juggle multiple
GitHub identities (e.g. personal vs work). If you do, also add matching
`Host` blocks to `~/.ssh/config`, e.g.:

```
Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes
    IdentityFile ~/.ssh/github-active

Host personal
    HostName github.com
    User git
    IdentitiesOnly yes
    IdentityFile ~/.ssh/github-personal

Host work
    HostName github.com
    User git
    IdentitiesOnly yes
    IdentityFile ~/.ssh/github-work
```

Then `git-use personal` or `git-use work` switches which key `github.com`
resolves to (symlinks `~/.ssh/github-active` at the target key). `git-use
status` shows the current one; `git-use doctor` validates the setup.

### 5.6 `~/.gitconfig` essentials

```ini
[init]
	defaultBranch = main
[credential "https://github.com"]
	helper =
	helper = !/opt/homebrew/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !/opt/homebrew/bin/gh auth git-credential
```

On Linux, replace `/opt/homebrew/bin/gh` with `$(command -v gh)`. This
makes `git push`/`pull` over HTTPS authenticate via `gh auth login` instead
of prompting for a password/token — run `gh auth login` once after this is
in place.

If this machine uses Git LFS, also add:

```ini
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
```

(requires `git-lfs` installed: `brew install git-lfs` / `apt install git-lfs`, then `git lfs install`)

---

## 6. Reload and verify

```bash
exec zsh
```

First run will pause for a few seconds while zinit clones itself and its
plugins (§5.4) — that's expected. Run `exec zsh` a second time afterward
and it should be near-instant; that's the actual thing to check into the
checklist below, not the first (cold) run.

Checklist — each should work with no errors:

- [ ] No `command not found: zinit` / no git-clone errors printed on shell start
- [ ] Prompt shows a colored `❯` and, inside a git repo, the branch name with a git glyph
- [ ] `ls` still works normally; `eza` plugin aliases (e.g. `ll`, `la` from oh-my-zsh's `eza` plugin) show icons and git status columns
- [ ] `cat somefile` shows syntax-highlighted output (via `bat`)
- [ ] Press `Ctrl+R` → atuin's fuzzy history search UI opens (not the default zsh history search)
- [ ] `z <partial-dir-name>` jumps to a previously-visited directory (zoxide)
- [ ] Typing a command shows greyed-out autosuggestion from history (zsh-autosuggestions)
- [ ] Valid commands highlight green as you type, invalid ones red (zsh-syntax-highlighting)
- [ ] `tmux` starts, mouse scroll/click works, status bar is dark with `❯ <session>` in green on the left
- [ ] Inside tmux, `prefix |` and `prefix -` split panes in the current directory
- [ ] `kubecolor version` / `k version` runs colorized (if kubectl-related work is done on this machine)
- [ ] Prompt icons (git branch glyph, language icons) render as actual glyphs, not boxes/`?` — if they don't, the terminal emulator isn't using the Nerd Font yet (recheck §3)

---

## 7. What's intentionally excluded

These were present on the source machine but are personal/product-specific,
not part of "terminal look and feel" — skip them unless explicitly wanted:

- `~/.autoenv` (per-directory env activation) and its `source
  ~/.autoenv/activate.sh` line
- Antigravity, OpenClaw, HuggingFace cache path, vllm-metal venv PATH
  entries — these are project-specific tool installs, not terminal config
- `~/.gitconfig-lilisolutions` and the `includeIf "gitdir:..."` block —
  client/employer-specific git identity, only relevant if working in that
  specific directory tree

---

## 8. Rollback

If you want an undo mechanism like the source machine has: before making
changes, snapshot the pre-existing `~/.zshrc` and `~/.tmux.conf` into a
timestamped backup directory, and write a small rollback script that
restores them and removes `~/.config/starship.toml`. Not required for a
fresh machine with no prior dotfiles — only useful when layering this setup
on top of an already-customized one.
