# termux-aliases

Instalador dos aliases de acesso à VPS (LifeOS) no Termux do Android.

> **Fonte:** repo privado `dotfiles` (`arch-on-android/modules/setup-aliases.sh`) — este arquivo é um **espelho automático** (GitHub Action no repo privado). Não editar aqui; edite no privado.

## Instalar / atualizar (no Termux)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/emmanuelcandido/termux-aliases/main/setup-aliases.sh)"
```

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
