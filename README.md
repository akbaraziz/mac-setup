# mac-setup

Automated macOS setup script that installs apps, CLI tools, shell plugins, and configures a fully-loaded Zsh environment. Run it on a fresh Mac (or an existing one) and get a consistent development setup in one shot.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Signed in to the **Mac App Store** (the script will exit if you're not)
- Internet connection
- Admin privileges (Homebrew installation requires it)

## Quick Start

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/mac-setup.git
cd mac-setup

# Make the script executable
chmod +x install.sh

# Run it
./install.sh
```

The script is idempotent — already-installed apps and tools are skipped, so you can safely re-run it.

## What It Does

### 1. Installs Homebrew

If Homebrew isn't present, it installs it automatically. Supports both `/opt/homebrew` (Apple Silicon) and `/usr/local` (Intel).

### 2. Installs Applications

| Method | Apps |
|--------|------|
| **Homebrew Cask** | 1Password, Antigravity, Bartender, BetterDisplay, Beyond Compare, Camtasia, ChatGPT, Claude, Claude Code, Codex, Cursor, Docker Desktop, Downie 4, draw.io, Dropbox, GitHub Desktop, Google Drive, iStat Menus, Keyboard Clean Tool, Keyboard Maestro, Latest, Microsoft Office 365, NotchNook, OBS Studio, Raycast, Screen Studio, Slack, Snagit, Spark, Spotify, SteerMouse, TopNotch, VSCode, Warp, Zoom |
| **Mac App Store** | Boom 3D, DaVinci Resolve, DetailsPro, Friendly Streaming Browser, Final Cut Pro, Klack, Logic Pro, Magnet, Okta Verify, Paste, TestFlight, Xcode, Xcode Command Line Tools |

> Mac App Store apps require a prior purchase/download from your Apple ID. The script will warn and skip if an app can't be installed.

### 3. Installs CLI Tools

| Category | Tools |
|----------|-------|
| **Cloud & DevOps** | AWS CLI, Azure CLI, Cloudflared, Gemini CLI, GitHub CLI (`gh`), Kubernetes CLI (`kubectl`), Resend CLI, Stripe CLI, Supabase CLI, Vercel CLI |
| **Languages & Runtimes** | bun, Node.js, nvm, rbenv, uv (Python) |
| **Shell & Prompt** | Oh My Posh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting |
| **Utilities** | git-delta, htop, thefuck, tldr |
| **npm globals** | Firecrawl CLI |

### 4. Configures the Shell

- **Oh My Zsh** — installed with plugins symlinked from Homebrew (zsh-autosuggestions, zsh-syntax-highlighting) and cloned from GitHub (you-should-use, zsh-bat)
- **Powerlevel10k** — theme linked into Oh My Zsh
- **Oh My Posh** — downloads the `powerlevel10k_rainbow` theme to `~/.config/oh-my-posh/themes/`
- **~/.zshrc** — writes a complete config with:
  - Powerlevel10k instant prompt
  - Oh My Zsh plugins (git, 1password, aws, azure, docker, docker-compose, gh, npm, kubectx, and more)
  - History settings (10k lines, dedup, shared across sessions)
  - 100+ shell aliases (git, Docker, Kubernetes, Terraform, AWS, networking, file management)
  - Custom functions (`mkcd`, `extract`)
  - Runtime inits for rbenv, nvm, uv, thefuck, bun
  - Claude Code environment variables

> **Backup**: If `~/.zshrc` already exists, the script backs it up to `~/.zshrc.bak.<timestamp>` before overwriting.

## Secrets

The script does **not** store secrets. Add tokens and private environment variables to `~/.zshrc.local`, which is sourced at the end of `~/.zshrc`:

```bash
# ~/.zshrc.local
export GITHUB_PERSONAL_ACCESS_TOKEN="your-token-here"
```

## Customizing

To add or remove apps, edit the `APPS` or `CLI_TOOLS` arrays in `install.sh`. Each entry follows the format:

```
"Display Name|kind|value|label|note"
```

Where `kind` is one of:
- `cask` — Homebrew cask (`brew install --cask`)
- `formula` — Homebrew formula (`brew install`)
- `mas` — Mac App Store app (value is the app ID)
- `npm` — npm global package (`npm install -g`)

### Finding Homebrew packages

Search for available casks and formulae at [https://formulae.brew.sh](https://formulae.brew.sh) or from the terminal:

```bash
# Search for a cask (GUI app)
brew search --cask <name>

# Search for a formula (CLI tool)
brew search --formula <name>
```

### Finding Mac App Store app IDs

Use the `mas` CLI to search the App Store and get the numeric ID needed for `mas` entries:

```bash
# Search by name
mas search "Final Cut"
#   424389933  Final Cut Pro           (10.8.1)
#   ...

# List apps already installed (with their IDs)
mas list
```

Use the ID from the first column (e.g., `424389933`) as the `value` in the `APPS` array.

## Included Shell Aliases

<details>
<summary>Click to expand full alias list</summary>

| Category | Examples |
|----------|---------|
| **Navigation** | `..`, `.2`–`.5`, `-` (cd back) |
| **File ops** | `mv`/`rm`/`cp` with `-i` safety, `lh`, `ll`, `mkdir` with `-pv` |
| **Git** | `gs` (status), `ga` (add), `gcm` (commit -m), `gp` (push), `gpu` (pull), `gundo` (soft reset) |
| **Docker** | `dps`, `dexec`, `dlogs`, `dcompup`, `dcompdown` |
| **Kubernetes** | `k`, `kgp` (get pods), `klo` (logs), `kex` (exec) |
| **Terraform** | `tf`, `tfi` (init), `tfp` (plan), `tfa` (apply) |
| **AWS** | `awslogin`, `awswhoami`, `awss3ls` |
| **Network** | `myip`, `ports`, `ping` (5 packets), `http` (Python HTTP server) |
| **System** | `top` (htop), `bru` (brew update+upgrade), `c` (clear), `e` (exit) |
| **Dev** | `ve` (create venv), `va` (activate), `vd` (deactivate) |
| **AI** | `cdp` (claude --dangerously-skip-permissions), `cu` (claude update) |

</details>

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `mas` says you're not signed in | Open the App Store app, sign in, then re-run the script |
| A Mac App Store app fails to install | You may need to purchase/download it manually first from the App Store |
| Powerlevel10k prompt looks broken | Install a [Nerd Font](https://www.nerdfonts.com/) and set it in your terminal emulator |
| `brew` command not found after install | Restart your terminal or run `eval "$(/opt/homebrew/bin/brew shellenv)"` |

## License

MIT
