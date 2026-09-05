#!/data/data/com.termux/files/usr/bin/bash
# setup-termux-shell.sh — Zsh + Starship (Nord) + TUI tools no Termux NATIVO (04/09)
# Fonte: dotfiles privado arch-on-android/modules/setup-termux-shell.sh — espelhado p/ termux-aliases.
# Base: configs/zsh/zshrc + configs/starship/starship.toml do ArchDroid (adaptado: sem bloco proot).
# Idempotente: sobrescreve as configs com a versão do repo (edite o repo, nunca o celular).
# Uso: bash -c "$(curl -fsSL https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/setup-termux-shell.sh)"

setup_termux_shell() {
    echo "==> [shell] Atualizando lista de pacotes"
    pkg update -y >/dev/null 2>&1 || true

    # thefuck NAO entra: nao e pacote apt do Termux (vem do pip, capenga no Android 11+) — 04/09
    echo "==> [shell] Instalando pacotes: zsh starship eza bat ripgrep zoxide fzf vim"
    pkg install -y zsh starship eza bat ripgrep zoxide fzf vim

    if ! command -v zsh >/dev/null 2>&1 || ! command -v starship >/dev/null 2>&1; then
        echo "  [ERRO] zsh/starship nao instalados — pkg install falhou? Rode 'pkg update' e tente de novo."
        return 1
    fi

    mkdir -p ~/.termux ~/.config

    # Backup das configs existentes antes de sobrescrever (04/09 — CEO perdeu configs)
    _ts="$(date +%Y%m%d-%H%M%S)"
    [ -f ~/.zshrc ] && cp ~/.zshrc "${HOME}/.zshrc.pre-termux-${_ts}" && echo "  backup: ~/.zshrc.pre-termux-${_ts}"
    [ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml "${HOME}/.config/starship.toml.pre-termux-${_ts}" && echo "  backup: ~/.config/starship.toml.pre-termux-${_ts}"

    echo "==> [shell] Fonte: JetBrainsMono Nerd Font (Mono, ~2.4MB)"
    curl -fsSL "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/NoLigatures/JetBrainsMonoNLNerdFontMono-Regular.ttf" -o ~/.termux/font.ttf \
        || echo "  [aviso] falha ao baixar a fonte — ícones/powerline do starship podem quebrar"

    echo "==> [shell] Cores Nord (~/.termux/colors.properties)"
    cat > ~/.termux/colors.properties <<'COLORSEOF'
# Nord — mesma paleta do ArchDroid (04/09)
background=#2E3440
foreground=#D8DEE9
cursor=#D8DEE9
color0=#3B4252
color1=#BF616A
color2=#A3BE8C
color3=#EBCB8B
color4=#81A1C1
color5=#B48EAD
color6=#88C0D0
color7=#E5E9F0
color8=#4C566A
color9=#BF616A
color10=#A3BE8C
color11=#EBCB8B
color12=#81A1C1
color13=#B48EAD
color14=#8FBCBB
color15=#ECEFF4
COLORSEOF

    echo "==> [shell] ~/.zshrc (edição Termux — sem bloco proot)"
    cat > ~/.zshrc <<'ZSHRCEOF'
# ── Zsh config — Termux nativo (edição 04/09, do ArchDroid sem proot) ──
# Fonte: https://github.com/emmanuelcandido/dotfiles (arch-on-android/configs/zsh/zshrc)

# ── PATH: garantir ~/.local/bin (bins vps-*) — /etc/profile do Termux e bash-only ──
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
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── Options ──
setopt AUTO_CD
setopt EXTENDED_GLOB
setopt NUMERIC_GLOB_SORT

# ── Zinit (auto-install se não existir) ──
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f "${ZINIT_HOME}/zinit.zsh" ]]; then
    command mkdir -p "${ZINIT_HOME}"
    command git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}" 2>/dev/null || \
        print -P "%F{red}[zinit] Falha ao clonar. Verifique conexão.%f"
fi
source "${ZINIT_HOME}/zinit.zsh" 2>/dev/null || true

# ── Plugins ──
zinit light zsh-users/zsh-autosuggestions
zinit light hlissner/zsh-autopair
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search

# fzf-tab: lazy load (só após prompt)
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# ── FZF ──
if command -v fzf &>/dev/null; then
    source <(fzf --zsh 2>/dev/null)
fi

# ── Zoxide ──
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ── Aliases ──
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias lt='eza -la --icons --sort=time'
alias tree='eza --tree --icons'
alias cat='bat --theme=Nord'
alias grep='rg'
alias du='du -h'
alias df='df -h'

# ── TheFuck ──
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias)"
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
export PAGER="bat"
ZSHRCEOF

    echo "==> [shell] ~/.config/starship.toml (Nord Powerline, do ArchDroid)"
    cat > ~/.config/starship.toml <<'STARSHIPEOF'
# Starship — Nord Pills (Termux, 04/09)
# Capsulas com pontas redondas (Powerline Extra da Nerd Font):
#   E0B4 = ponta esquerda  ·  E0B6 = ponta direita
# Validado sem warnings no starship 1.25.1/1.26 (username usa style_user, nao style)

add_newline = false

format = """\
$username\
$directory\
$git_branch\
$git_status\
$fill\
$time\
$line_break\
$character"""

# ═══ Linha 1 — Pílulas ═══

[username]
style_user = ""
style_root = ""
format = "[](fg:#5E81AC)[ $user ](bg:#5E81AC fg:#2E3440)[](fg:#5E81AC) "

[directory]
style = ""
format = "[](fg:#81A1C1)[  $path  ](bg:#81A1C1 fg:#2E3440)[](fg:#81A1C1) "
truncation_length = 3
truncation_symbol = "…/"
read_only = " "

[git_branch]
style = ""
format = "[](fg:#88C0D0)[  $branch  ](bg:#88C0D0 fg:#2E3440)[](fg:#88C0D0)"
only_attached = true

[git_status]
style = "fg:#88C0D0"
format = "[$all_status$ahead_behind](fg:#88C0D0)"
conflicted = "="
staged = "+"
modified = "!"
deleted = "✗"
renamed = "→"
untracked = "?"
ahead = " ↑"
behind = " ↓"
diverged = " ⇕"

# ═══ Linha 1 — Direita ═══

[fill]
symbol = " "

[time]
disabled = false
style = "fg:#4C566A"
format = "[$time](fg:#4C566A bold)"
time_format = "%H:%M"

# ═══ Linha 2 — Cursor ═══

[character]
success_symbol = "[❯](bold #A3BE8C)"
error_symbol = "[❯](bold #BF616A)"
format = "$symbol "

# ═══ Desligados (ruído no celular) ═══
[os]
disabled = true

[hostname]
disabled = true

[cmd_duration]
disabled = true

[python]
disabled = true

[nodejs]
disabled = true

[rust]
disabled = true

[golang]
disabled = true

[battery]
disabled = true

[docker]
disabled = true

[kubernetes]
disabled = true
STARSHIPEOF

    if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings 2>/dev/null || true
    fi

    if [ -d /data/data/com.termux ] && [ -x /data/data/com.termux/files/usr/bin/zsh ]; then
        echo "==> [shell] Trocando shell padrão para zsh (chsh -s zsh)"
        chsh -s zsh
        echo "  Pronto! Abra uma NOVA sessão do Termux (a atual continua bash)."
    else
        echo "  (fora do Termux — chsh pulado)"
    fi

    echo "==> [shell] Concluído: zsh + Starship Nord + tools. Fonte/cores aplicadas em nova sessão."
}

# Execução direta instala (idempotente): arquivo (BS==$0) ou bash -c/stdin (BS vazio).
# Quando sourceado (apply-configs.sh), só define a função.
case "${BASH_SOURCE[0]}" in
    ""|"$0") setup_termux_shell ;;
esac
