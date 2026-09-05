# termux-aliases

Instaladores do Termux do Android (acesso à VPS LifeOS + shell Nord).

> **Fonte:** repo privado `dotfiles` (`arch-on-android/modules/`) — estes arquivos são **espelho automático** (GitHub Action no repo privado). Não editar aqui; edite no privado.

## 1. Aliases de acesso à VPS

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/setup-aliases.sh)"
```

Instala o `mosh` se ausente e cria em `~/.local/bin`:

Idempotente: limpa versões antigas e (re)instala tudo. Cria em `~/.local/bin`:

| Comando | O que faz |
|---|---|
| `start-arch` / `stop-arch` / `uninstall-arch` | Inicia/para o Arch (proot) + i3 |
| `apply-configs` | Aplica configs do ArchDroid |
| `vps-shell` | Shell direto na VPS (mosh), já em `/root/lifeos` |
| `vps-tmux` / `vps-tmux-kill` | Menu tmux da VPS |
| `vps-claude` / `-safe` / `-resume` | Claude Code na VPS (YOLO / com permissões / resume) |
| `vps-cc-or` | Claude Code via OpenRouter na VPS, em `/root/lifeos` |
| `vps-pi` / `vps-pi-coder` | Pi (perfil founder / coder) na VPS, em `/root/lifeos` |
| `vps-herdr` | Anexa a sessão herdr (tmux `herdr-coder`) na VPS |
| `vps-deploy` | Git pull + deploy na VPS |
| `vps-logs` | Logs da VPS (journalctl) |
| `ccgram-restart` | Reinicia o ccgram |

**Pré-requisito:** `mosh` instalado no Termux (`pkg install mosh`). A chave do OpenRouter vive em `~/.hermes/.env` na VPS (nada de segredo neste repo).

## 2. Shell — Zsh + Starship Nord (04/09)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/setup-termux-shell.sh)"
```

Instala `zsh starship eza bat ripgrep zoxide fzf thefuck vim`, aplica:
- Fonte **JetBrains Mono Nerd Font** (`~/.termux/font.ttf`)
- Cores **Nord** (`~/.termux/colors.properties`)
- `~/.zshrc` (edição Termux do ArchDroid — zinit + plugins, sem bloco proot)
- `~/.config/starship.toml` (Nord Powerline)
- **Troca o shell padrão para zsh** (`chsh -s zsh`) — abra uma **nova sessão** do Termux para valer
