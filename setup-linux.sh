#!/usr/bin/env bash
# setup-linux-shell.sh — Zsh + Starship Nord (com linguagens) + tools no Linux (05/09)
# Distros: Arch (pacman) · Debian/Ubuntu (apt) · Fedora (dnf — parcial)
# Espelhado p/ github.com/emmanuelcandido/termux-aliases (setup-linux.sh).
# Uso: bash -c "$(curl -fsSL https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/setup-linux.sh)"

setup_linux_shell() {
    echo "==> [linux] Detectando gerenciador de pacotes"
    local pm=""
    if command -v pacman >/dev/null 2>&1; then pm="pacman"
    elif command -v apt-get >/dev/null 2>&1; then pm="apt"
    elif command -v dnf >/dev/null 2>&1; then pm="dnf"
    else echo "  [ERRO] gerenciador nao suportado (pacman/apt/dnf)"; return 1; fi
    echo "  -> ${pm}"

    echo "==> [linux] Instalando pacotes base: zsh git vim ripgrep fzf zoxide bat"
    case "$pm" in
        pacman)
            pacman -S --noconfirm --needed zsh git vim ripgrep fzf zoxide bat eza starship ttf-jetbrains-mono-nerd
            ;;
        apt)
            apt-get update -y >/dev/null 2>&1 || true
            apt-get install -y zsh git vim ripgrep fzf zoxide bat
            # eza e starship nao estao no apt padrao do Ubuntu — instala por binario
            if ! command -v eza >/dev/null 2>&1; then
                echo "  -> baixando eza (release GitHub)"
                curl -fsSL -o /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
                    && tar xzf /tmp/eza.tar.gz -C /usr/local/bin eza && rm -f /tmp/eza.tar.gz
            fi
            if ! command -v starship >/dev/null 2>&1; then
                echo "  -> instalando starship (script oficial)"
                curl -fsSL https://starship.rs/install.sh | sh -s -- -y
            fi
            ;;
        dnf)
            dnf install -y zsh git vim ripgrep fzf zoxide bat eza starship
            ;;
    esac

    echo "==> [linux] Fonte JetBrains Mono Nerd (para glifos do starship)"
    case "$pm" in
        pacman) : ;;  # ja instalada via ttf-jetbrains-mono-nerd
        *)
            mkdir -p ~/.local/share/fonts
            curl -fsSL "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/NoLigatures/JetBrainsMonoNLNerdFontMono-Regular.ttf" \
                -o ~/.local/share/fonts/JetBrainsMonoNerdFontMono-Regular.ttf \
                && fc-cache -f ~/.local/share/fonts >/dev/null 2>&1 \
                && echo "  fonte instalada (selecione JetBrainsMono Nerd no seu terminal)"
            ;;
    esac

    mkdir -p ~/.config

    echo "==> [linux] ~/.config/starship.toml (tema Nord + linguagens)"
    curl -fsSL "https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/starship-linux.toml" -o ~/.config/starship.toml \
        || echo "  [aviso] falha ao baixar starship.toml — tema nao aplicado"

    echo "==> [linux] ~/.zshrc (backup do atual em .zshrc.pre-linux-<data>)"
    _ts="$(date +%Y%m%d-%H%M%S)"
    [ -f ~/.zshrc ] && cp ~/.zshrc "${HOME}/.zshrc.pre-linux-${_ts}" && echo "  backup: ~/.zshrc.pre-linux-${_ts}"
    cat > ~/.zshrc <<'ZSHRCEOF'
# ── Zsh config — Linux (edicao 05/09, do setup-linux-shell.sh) ──

# ── PATH: garantir ~/.local/bin (starship via script oficial, bins locais) ──
export PATH="${HOME}/.local/bin:${PATH}"

# ── History ──
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HOME}/.zsh_history"
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# ── Completion ──
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select

# ── Options ──
setopt AUTO_CD
setopt EXTENDED_GLOB

# ── Aliases da VPS (cc-or/pi/pi-coder — fonte da chave ~/.hermes/.env) ──
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# ── Aliases visuais ──
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias lt='eza -la --icons --sort=time'
alias tree='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias du='du -h'
alias df='df -h'

# ── FZF ──
if command -v fzf &>/dev/null; then
    source <(fzf --zsh 2>/dev/null)
fi

# ── Zoxide ──
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ── Bat ──
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="Nord"

# ── Starship ──
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ── Editor ──
export EDITOR="vim"
export VISUAL="vim"
ZSHRCEOF

    # Se nao ha ~/.bash_aliases, cria com o bloco cc-or/pi/pi-coder (fonte unica ~/.hermes/.env)
    if [ ! -f ~/.bash_aliases ]; then
        echo "==> [linux] ~/.bash_aliases nao existia — criando com cc-or/pi/pi-coder"
        cat > ~/.bash_aliases <<'BASHALIASESEOF'
# ===== OpenRouter / Claude Code / Pi =====
# Fonte unica da chave: ~/.hermes/.env
__or_key() {
  grep '^OPENROUTER_API_KEY=' ~/.hermes/.env 2>/dev/null | head -1 | cut -d= -f2- | sed -E "s/^[\"']//; s/[\"']$//"
}
cc-or() {
  local m="deepseek/deepseek-v4-flash:floor"
  [[ "$1" == "--model" && -n "$2" ]] && { m="$2"; shift 2; }
  export ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1" \
         ANTHROPIC_AUTH_TOKEN="$(__or_key)" \
         ANTHROPIC_API_KEY="" \
         ANTHROPIC_MODEL="$m" \
         ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek/deepseek-v4-pro-0813" \
         ANTHROPIC_DEFAULT_SONNET_MODEL="$m" \
         ANTHROPIC_DEFAULT_HAIKU_MODEL="$m" \
         CLAUDE_CODE_SUBAGENT_MODEL="$m"
  claude "$@"
}
pi() {
  export OPENROUTER_API_KEY="$(__or_key)"
  local key="$(__or_key)"
  if [[ "$*" == *"--model"* || "$*" == *"--provider"* ]]; then
    command pi --api-key "$key" "$@"
  else
    command pi --provider openrouter --model "deepseek/deepseek-v4-flash:floor" --api-key "$key" "$@"
  fi
}
pi-coder() {
  export OPENROUTER_API_KEY="$(__or_key)"
  local key="$(__or_key)"
  if [[ "$*" == *"--model"* || "$*" == *"--provider"* ]]; then
    PI_CODING_AGENT_DIR="$HOME/.pi/profiles/coder" command pi --api-key "$key" "$@"
  else
    PI_CODING_AGENT_DIR="$HOME/.pi/profiles/coder" command pi --provider openrouter --model "deepseek/deepseek-v4-flash:floor" --api-key "$key" "$@"
  fi
}
BASHALIASESEOF
    fi

    # Trocar shell padrao para zsh (se o zsh existe e nao e o shell atual)
    if command -v zsh >/dev/null 2>&1 && [ "$SHELL" != "$(command -v zsh)" ]; then
        echo "==> [linux] Trocando shell padrao para zsh (chsh -s zsh)"
        chsh -s "$(command -v zsh)"
        echo "  Pronto! Abra uma NOVA sessao (a atual continua no shell antigo)."
    else
        echo "  (zsh ja e o shell padrao ou ausente — nada a trocar)"
    fi

    echo "==> [linux] Concluido. Tema: estrela Nord + linguagens; aliases cc-or/pi/pi-coder ativos no zsh."
}

# Execucao direta (arquivo ou bash -c/stdin); source so define.
case "${BASH_SOURCE[0]}" in
    ""|"$0") setup_linux_shell ;;
esac
