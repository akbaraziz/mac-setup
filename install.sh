#!/usr/bin/env bash
set -euo pipefail

# Non-interactive installer generated from Installed_Apps.md
# Automatically installs mapped Homebrew casks and Mac App Store apps.
# Already-installed apps are skipped.

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

ensure_mas() {
  if ! command -v mas >/dev/null 2>&1; then
    log "Installing mas (Mac App Store CLI)"
    brew install mas
  fi
}

ensure_app_store_login() {
  ensure_mas
  if ! mas account >/dev/null 2>&1; then
    warn "You are not signed in to the Mac App Store."
    warn "Open the App Store app, sign in once, then rerun this script."
    exit 1
  fi
}

is_cask_installed() {
  local token="$1"
  brew list --cask "$token" >/dev/null 2>&1
}

is_mas_installed() {
  local app_id="$1"
  mas list | awk '{print $1}' | grep -qx "$app_id"
}

install_cask() {
  local token="$1"
  if is_cask_installed "$token"; then
    info "[skip] cask already installed: $token"
  else
    info "[install] brew install --cask $token"
    brew install --cask "$token"
  fi
}

is_formula_installed() {
  local name="${1##*/}"   # strip tap prefix, e.g. stripe/stripe-cli/stripe → stripe
  brew list --formula "$name" >/dev/null 2>&1
}

install_formula() {
  local formula="$1"
  local name="${formula##*/}"
  if is_formula_installed "$formula"; then
    info "[skip] formula already installed: $name"
  else
    info "[install] brew install $formula"
    brew install "$formula"
  fi
}

is_npm_global_installed() {
  npm list -g --depth=0 "$1" >/dev/null 2>&1
}

install_npm_global() {
  local pkg="$1"
  local label="$2"
  if is_npm_global_installed "$pkg"; then
    info "[skip] npm global already installed: $pkg"
  else
    info "[install] npm install -g $pkg"
    npm install -g "$pkg" || warn "Could not install npm package: $pkg"
  fi
}

install_mas() {
  local app_id="$1"
  local name="$2"
  if is_mas_installed "$app_id"; then
    info "[skip] App Store app already installed: $name ($app_id)"
  else
    info "[install] mas install $app_id  # $name"
    mas install "$app_id" || warn "Could not install $name ($app_id). You may need to purchase it first or re-authenticate in the App Store."
  fi
}

ensure_brew
log "Updating Homebrew"
brew update
ensure_app_store_login

# original|kind|value|label|note
APPS=(
  "Antigravity|cask|antigravity|Antigravity|"
  "1 Password|cask|1password|1Password|"
  "Bartender|cask|bartender|Bartender|"
  "BetterDisplay|cask|betterdisplay|BetterDisplay|"
  "Beyond Compare|cask|beyond-compare|Beyond Compare|"
  "Boom 3D|mas|1233048948|Boom 3D|"
  "Camtasia|cask|camtasia|Camtasia|"
  "ChatGPT|cask|chatgpt|ChatGPT|"
  "Claude|cask|claude|Claude|"
  "Claude Code|cask|claude-code|Claude Code|"
  "Codex|cask|codex-app|Codex|"
  "Cursor|cask|cursor|Cursor|"
  "Davinci Resolve|mas|571213070|DaVinci Resolve|"
  "DetailsPro|mas|1524366536|DetailsPro|"
  "Docker Desktop|cask|docker-desktop|Docker Desktop|"
  "Downie 4|cask|downie|Downie|"
  "Draw.io|cask|drawio|draw.io|"
  "Dropbox|cask|dropbox|Dropbox|"
  "Final Cut|mas|424389933|Final Cut Pro|"
  "Friendly Streaming Browser|mas|553245401|Friendly Streaming Browser|"
  "Github Desktop|cask|github|GitHub Desktop|"
  "Google Chrome|cask|google-chrome|Google Chrome|"
  "Google Drive|cask|google-drive|Google Drive|"
  "iStats Menu|cask|istat-menus|iStat Menus|"
  "Keyboard Maestro|cask|keyboard-maestro|Keyboard Maestro|"
  "Keyboard Clean Tool|cask|keyboardcleantool|Keybard Clean Tool|"
  "Klack|mas|6446206067|Klack|"
  "Latest|cask|latest|Latest|"
  "Logic Pro|mas|634148309|Logic Pro|"
  "Magnet|mas|441258766|Magnet|"
  "Microsoft Office|cask|microsoft-office|Microsoft Office 365|"
  "NotchNook|cask|notchnook|NotchNook|"
  "OBS|cask|obs|OBS Studio|"
  "Okta Verify|mas|490179405|Okta Verify|"
  "Paste|mas|967805235|Paste|"
  "Raycast|cask|raycast|Raycast|"
  "Screen Studio|cask|screen-studio|Screen Studio|"
  "Slack|cask|slack|Slack|"
  "Snagit|cask|snagit|Snagit|"
  "Spark|cask|readdle-spark|Spark|"
  "Spotify|cask|spotify|Spotify|"
  "SteerMouse|cask|steermouse|SteerMouse|"
  "TestFlight|mas|899247664|TestFlight|"
  "TopNotch|cask|topnotch|TopNotch|"
  "Warp|cask|warp|Warp|"
  "Zoom|cask|zoom|Zoom|"
  "XCode|mas|497799835|XCode|"
  "XCode Command Line Tools|mas|497799835|XCode Command Line Tools|"
)

log "Starting app installation"
info "Already-installed apps will be skipped."
info "Mac App Store apps require an active App Store login."

for entry in "${APPS[@]}"; do
  IFS='|' read -r original kind value label note <<< "$entry"

  case "$kind" in
    cask)
      install_cask "$value"
      ;;
    mas)
      install_mas "$value" "$label"
      ;;
    formula)
      install_formula "$value"
      ;;
    npm)
      install_npm_global "$value" "$label"
      ;;
    *)
      warn "Unknown app type for $original. Skipping."
      ;;
  esac
done

# ---------------------------------------------------------------------------
# CLI Tools
# formula = brew install (no --cask); supports tap paths like org/tap/pkg
# npm     = npm install -g
# ---------------------------------------------------------------------------

# original|kind|value|label|note
CLI_TOOLS=(
  "GitHub CLI|formula|gh|GitHub CLI|"
  "AWS CLI|formula|awscli|AWS CLI|"
  "Azure CLI|formula|azure-cli|Azure CLI|"
  "Cloudflared|formula|cloudflared|Cloudflared|"
  "Firecrawl CLI|npm|firecrawl-cli|Firecrawl CLI|"
  "Gemini CLI|formula|google/gemini-cli/gemini-cli|Gemini CLI|"
  "Kubernetes CLI|formula|kubernetes-cli|kubectl|"
  "Node.js|formula|node|Node.js|"
  "Oh My Posh|formula|oh-my-posh|Oh My Posh|"
  "Resend CLI|formula|resend/tap/resend|Resend CLI|"
  "Stripe CLI|formula|stripe/stripe-cli/stripe|Stripe CLI|"
  "Supabase CLI|formula|supabase/tap/supabase|Supabase CLI|"
  "Vercel CLI|formula|vercel/cli/vercel|Vercel CLI|"
  # Shell & prompt
  "powerlevel10k|formula|powerlevel10k|powerlevel10k|"
  "zsh-autosuggestions|formula|zsh-autosuggestions|zsh-autosuggestions|"
  "zsh-syntax-highlighting|formula|zsh-syntax-highlighting|zsh-syntax-highlighting|"
  # Referenced in .zshrc
  "git-delta|formula|git-delta|git-delta|"
  "thefuck|formula|thefuck|thefuck|"
  "tldr|formula|tldr|tldr|"
  "htop|formula|htop|htop|"
  "rbenv|formula|rbenv|rbenv|"
  "uv|formula|uv|uv|"
  "bun|formula|oven-sh/bun/bun|bun|"
  "nvm|formula|nvm|nvm|"
)

log "Starting CLI tool installation"
info "Already-installed CLI tools will be skipped."

for entry in "${CLI_TOOLS[@]}"; do
  IFS='|' read -r original kind value label note <<< "$entry"

  case "$kind" in
    formula)
      install_formula "$value"
      ;;
    npm)
      install_npm_global "$value" "$label"
      ;;
    *)
      warn "Unknown tool type for $original. Skipping."
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Oh My Zsh + Powerlevel10k setup
# ---------------------------------------------------------------------------

setup_omz() {
  log "Setting up Oh My Zsh"

  # Install oh-my-zsh non-interactively if not already present
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "[skip] Oh My Zsh already installed"
  else
    info "[install] Oh My Zsh"
    RUNZSH=no CHSH=no \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # zsh-autosuggestions plugin symlink into oh-my-zsh custom plugins
  local auto_dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [[ -d "$auto_dst" ]]; then
    info "[skip] zsh-autosuggestions plugin already linked"
  else
    info "[link] zsh-autosuggestions into oh-my-zsh plugins"
    local auto_src
    auto_src="$(brew --prefix)/share/zsh-autosuggestions"
    if [[ -d "$auto_src" ]]; then
      ln -sf "$auto_src" "$auto_dst"
    else
      warn "zsh-autosuggestions not found at $auto_src — did brew install succeed?"
    fi
  fi

  # zsh-syntax-highlighting plugin symlink
  local syntax_dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [[ -d "$syntax_dst" ]]; then
    info "[skip] zsh-syntax-highlighting plugin already linked"
  else
    info "[link] zsh-syntax-highlighting into oh-my-zsh plugins"
    local syntax_src
    syntax_src="$(brew --prefix)/share/zsh-syntax-highlighting"
    if [[ -d "$syntax_src" ]]; then
      ln -sf "$syntax_src" "$syntax_dst"
    else
      warn "zsh-syntax-highlighting not found at $syntax_src — did brew install succeed?"
    fi
  fi

  # you-should-use plugin (not in brew, clone directly)
  local ysu_dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
  if [[ -d "$ysu_dst" ]]; then
    info "[skip] you-should-use plugin already present"
  else
    info "[install] you-should-use plugin"
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$ysu_dst"
  fi

  # zsh-bat plugin (not in brew, clone directly)
  local bat_dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-bat"
  if [[ -d "$bat_dst" ]]; then
    info "[skip] zsh-bat plugin already present"
  else
    info "[install] zsh-bat plugin"
    git clone https://github.com/fdellwing/zsh-bat.git "$bat_dst"
  fi

  # powerlevel10k theme symlink into oh-my-zsh custom themes
  local p10k_dst="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$p10k_dst" ]]; then
    info "[skip] powerlevel10k theme already linked"
  else
    info "[link] powerlevel10k into oh-my-zsh themes"
    local p10k_src
    p10k_src="$(brew --prefix)/share/powerlevel10k"
    if [[ -d "$p10k_src" ]]; then
      ln -sf "$p10k_src" "$p10k_dst"
    else
      warn "powerlevel10k not found at $p10k_src — did brew install succeed?"
    fi
  fi
}

# ---------------------------------------------------------------------------
# oh-my-posh + p10k theme
# ---------------------------------------------------------------------------

setup_ohmyposh() {
  log "Setting up oh-my-posh with p10k theme"

  local theme_dir="$HOME/.config/oh-my-posh/themes"
  local theme_file="$theme_dir/powerlevel10k_rainbow.omp.json"

  mkdir -p "$theme_dir"

  if [[ -f "$theme_file" ]]; then
    info "[skip] oh-my-posh p10k theme already present"
  else
    info "[download] powerlevel10k_rainbow.omp.json"
    curl -fsSL \
      "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_rainbow.omp.json" \
      -o "$theme_file" \
      || warn "Could not download oh-my-posh p10k theme. Check your connection."
    info "[ok] theme saved to $theme_file"
  fi
}

# ---------------------------------------------------------------------------
# gstack (Claude Code skills)
# ---------------------------------------------------------------------------

setup_gstack() {
  log "Setting up gstack (Claude Code skills)"

  local gstack_dir="$HOME/.claude/skills/gstack"

  if [[ -d "$gstack_dir" ]]; then
    info "[skip] gstack already installed at $gstack_dir"
  else
    info "[install] cloning gstack"
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$gstack_dir"
  fi

  info "[setup] running gstack setup"
  (cd "$gstack_dir" && ./setup) || warn "gstack setup failed — you can retry with: cd $gstack_dir && ./setup"
}

# ---------------------------------------------------------------------------
# Write ~/.zshrc
# ---------------------------------------------------------------------------

write_zshrc() {
  log "Writing ~/.zshrc"

  local zshrc="$HOME/.zshrc"

  # Back up any existing file
  if [[ -f "$zshrc" ]]; then
    local backup="$zshrc.bak.$(date +%Y%m%d%H%M%S)"
    warn "Existing ~/.zshrc found — backing up to $backup"
    cp "$zshrc" "$backup"
  fi

  cat > "$zshrc" << 'ZSHRC_EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git 1password aliases alias-finder aws azure brew colorize colored-man-pages common-aliases docker docker-compose gh npm kubectx zsh-autosuggestions you-should-use zsh-bat thefuck zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Directory Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt nocaseglob
setopt nocasematch

# Completion System
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Tool-specific Completions
if command -v terraform >/dev/null 2>&1; then
  compdef '_bash_complete -o nospace -C $(command -v terraform)' terraform
fi
if command -v aws_completer >/dev/null 2>&1; then
  compdef '_bash_complete -C $(command -v aws_completer)' aws
fi

# Path Configuration
typeset -U path
path=(
  $HOME/bin
  /usr/local/bin
  $HOME/.local/bin
  $HOME/local/bin
  $path
)

# ===========================================
# Secrets — set these in ~/.zshrc.local
# export GITHUB_PERSONAL_ACCESS_TOKEN="your-token-here"
# ===========================================

# AWS Configuration
export AWS_PROFILE=akbar-admin
export AWS_DEFAULT_REGION=us-east-1
export AWS_SDK_LOAD_CONFIG=1

# ===========================================
# Tool Configurations
# ===========================================

# git-delta Configuration
if command -v delta &> /dev/null; then
    export GIT_PAGER="delta"
fi

# tldr Configuration
export TLDR_COLOR_NAME="cyan"
export TLDR_COLOR_DESCRIPTION="white"
export TLDR_COLOR_EXAMPLE="green"
export TLDR_COLOR_COMMAND="red"
export TLDR_COLOR_PARAMETER="blue"

# ===========================================
# Directory Navigation aliases
# ===========================================
alias ..='cd ..'
alias .2='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias cd..='cd ..'
alias -- -='cd -'

# ===========================================
# File Management & Listing
# ===========================================
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias ln='ln -i'
alias mkdir='mkdir -pv'
alias tarx='tar -xvzf'
alias tarc='tar -cvzf'
alias untar='tar -xvf'
alias untargz='tar -xvzf'
alias lh='ls -lah'
alias ll='ls -la'
alias lr='ls -lR'
alias lf='ls -l | grep "^-"'
alias ld='ls -l | grep "^d"'
alias cpr='cp -R'
alias rmr='rm -r'

# ===========================================
# Environment Variables & System Info
# ===========================================
alias genv='printenv |grep -i'
alias path='echo -e ${PATH//:/\\n} | less'
alias now='date +"%T"'
alias nowd='date +"%m-%d-%Y"'
alias top='htop'
if [[ "$OSTYPE" == darwin* ]]; then
  alias df='df -h'
  alias du='du -ch'
  alias duh='du -h -d 1'
  alias os='sw_vers'
  alias cpuinfo='sysctl -a | grep machdep.cpu'
  alias meminfo='vm_stat'
else
  alias df='df -B GB'
  alias du='du -ch'
  alias duh='du -h --max-depth=1'
  alias free='free -mt'
  alias os='lsb_release -a'
  alias cpu='cat /proc/cpuinfo'
  alias cpuinfo='lscpu'
  alias mem='cat /proc/meminfo'
  alias meminfo='free -m -l -t'
  alias temp='sensors'
fi

# ===========================================
# System Updates & Package Management
# ===========================================
alias c='clear'
alias e='exit'
alias bru="brew update && brew upgrade"

# ===========================================
# Search
# ===========================================
alias find='find . -iname'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ===========================================
# Network
# ===========================================
if [[ "$OSTYPE" == darwin* ]]; then
  alias ports='lsof -nP -iTCP -sTCP:LISTEN'
  alias netcons='netstat -anv | grep LISTEN'
  alias ipconfig='ifconfig'
  alias ports-open='lsof -i -P -n | grep LISTEN'
else
  alias ports='netstat -tulanp'
  alias netcons='netstat -tupn'
  alias ipconfig='ip addr show'
  alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'
  alias ports-open='sudo lsof -i -P -n | grep LISTEN'
fi
alias myip='curl ipinfo.io/ip'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i -0.2'
alias http='python3 -m http.server'
if [[ "$OSTYPE" == darwin* ]]; then
  alias wifi='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s'
  alias dns='scutil --dns'
else
  alias wifi='nmcli d wifi list'
  alias dns='cat /etc/resolv.conf'
fi
alias speed='speedtest-cli'
alias tcpdump='sudo tcpdump -i any'

# ===========================================
# Git Aliases
# ===========================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gal='git add -u'
alias gall='git add -A'
alias gl='git log'
alias gll='git log --oneline'
alias gpu='git pull'
alias gpua='git pull -A'
alias gd='git diff'
alias gds='git diff --staged'
alias gcm='git commit -m'
alias gc='git checkout'
alias gm='git merge'
alias gf='git fetch'
alias gp='git push'
alias gundo='git reset --soft HEAD~1'
alias gclean='git clean -df'
alias gbr='git branch'
alias gco='git checkout -b'

# ===========================================
# Docker
# ===========================================
alias dc='docker-compose'
alias di='docker images'
alias dps='docker ps'
alias dpa='docker ps -a'
alias drm='docker rm'
alias drmi='docker rmi'
alias drun='docker run'
alias dexec='docker exec -it'
alias dbuild='docker build'
alias dstart='docker start'
alias dstop='docker stop'
alias dlogs='docker logs'
alias dcp='docker cp'
alias dnet='docker network'
alias dvol='docker volume'
alias dcomp='docker-compose'
alias dcompup='docker-compose up'
alias dcompdown='docker-compose down'
alias dcompbuild='docker-compose build'
alias dcompstart='docker-compose start'
alias dcompstop='docker-compose stop'
alias dcomplogs='docker-compose logs'
alias dcompexec='docker-compose exec'
alias dcompdownv='docker-compose down -v'
alias dcompupb='docker-compose up --build'

# ===========================================
# Kubernetes
# ===========================================
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgc='kubectl get componentstatuses'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pods'
alias kds='kubectl describe svc'
alias kdc='kubectl describe componentstatuses'
alias kdi='kubectl describe ingress'
alias kdn='kubectl describe nodes'
alias kd='kubectl describe'
alias krm='kubectl delete'
alias krmf='kubectl delete --force'
alias krmn='kubectl delete --namespace'
alias krmnf='kubectl delete --namespace --force'
alias kex='kubectl exec -it'
alias klo='kubectl logs'
alias klof='kubectl logs -f'
alias klof1='kubectl logs -f --tail=1'
alias klo1='kubectl logs --tail=1'

# ===========================================
# Terraform
# ===========================================
alias tf='terraform'
alias tfi='terraform init'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfp='terraform plan'
alias tff='terraform fmt'
alias tfs='terraform show'
alias tfv='terraform validate'
alias tfws='terraform workspace'
alias tfwsl='terraform workspace list'
alias tfwsc='terraform workspace create'
alias tfwsd='terraform workspace delete'
alias tfwss='terraform workspace select'

# ===========================================
# AWS
# ===========================================
alias awscli='aws'
alias awslogin='aws sso login'
alias awslogout='aws sso logout'
alias awswhoami='aws sts get-caller-identity'
alias awslist='aws s3 ls'
alias ssha='ssh -i akbaraziz.aws.pem'
alias awss3='aws s3'
alias awsec2='aws ec2'
alias awsiam='aws iam'
alias awslambda='aws lambda'
alias awseks='aws eks'
alias awsecr='aws ecr'
alias awss3ls='aws s3 ls'
alias awss3cp='aws s3 cp'
alias awss3sync='aws s3 sync'

# ===========================================
# Security
# ===========================================
alias ssl-check='openssl x509 -text -noout -in'
alias ssht='ssh -T'

# ===========================================
# Log Viewing
# ===========================================
alias glf='tail -f /var/log/system.log'
alias alf='tail -f /var/log/auth.log'

# ===========================================
# Development Tools
# ===========================================
alias code.='code .'
alias ve='python3 -m venv ./venv'
alias va='source ./venv/bin/activate'
alias vd='deactivate'

# ===========================================
# LLM / AI Tools
# ===========================================
alias cdp="claude --dangerously-skip-permissions"
alias cuu='brew upgrade claude-code"
alias cai="cd $HOME/Dropbox/GitHub_Repos/Projects/conduitai-bolt"

# ===========================================
# Custom Functions
# ===========================================

# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ===========================================
# Runtime tool inits
# ===========================================

# Python (Homebrew)
export PATH="/opt/homebrew/opt/python@3.14/bin:$PATH"

# powerlevel10k theme (via brew)
source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme

# p10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Docker CLI completions
fpath=(/Users/akbar/.docker/completions $fpath)

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# uv shell completion
eval "$(uv generate-shell-completion zsh)"

# rbenv
eval "$(rbenv init - zsh)"

# Claude Code
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
export CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS=64000

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# kiro shell integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# thefuck
eval $(thefuck --alias)

# Load local overrides/secrets (tokens, private env vars, etc.)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
ZSHRC_EOF

  info "[ok] ~/.zshrc written"
  info "[note] Add secrets (GITHUB_PERSONAL_ACCESS_TOKEN etc.) to ~/.zshrc.local"
}

# ---------------------------------------------------------------------------
# Run shell setup
# ---------------------------------------------------------------------------

setup_omz
setup_ohmyposh
setup_gstack
write_zshrc

log "Done"