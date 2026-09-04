#!/data/data/com.termux/files/usr/bin/bash
# modules/setup-aliases.sh — Cria start-arch, stop-arch, uninstall-arch no ~

setup_aliases() {
    local BIN_DIR="${HOME}/.local/bin"
    mkdir -p "${BIN_DIR}"

    # ── Limpeza de obsoletos (versões antigas que saíram da lista) ──
    for _old in vps-ssh vps-ccbot ccbot ccbot-restart vps-ccbot-restart; do
        rm -f "${BIN_DIR}/${_old}" "${HOME}/${_old}"
    done

    # ── start-arch ──
    cat > "${BIN_DIR}/start-arch" << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# start-arch — Inicia Arch Linux + i3 via proot-distro + Termux:X11

termux-wake-lock 2>/dev/null || true

export DISPLAY=:0

# GPU config
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy

# Mata orphans Electron/Chromium que acumulam memoria (OOM killer prevention)
pkill -f "shm-helper" 2>/dev/null || true
pkill -f "[e]lectron" 2>/dev/null || true

cleanup() {
    echo "Parando sessão..."
    pkill -9 -f "termux.x11" 2>/dev/null
    pkill -9 -f "pulseaudio" 2>/dev/null
    termux-wake-unlock 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Inicia PulseAudio (unset PULSE_SERVER temporariamente senão ele recusa iniciar)
pulseaudio --check 2>/dev/null || {
    echo "[audio] Iniciando PulseAudio..."
    env -u PULSE_SERVER pulseaudio --start --exit-idle-time=-1
    sleep 1
    pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
}

# Instala Termux:X11 se não existir
command -v termux-x11 >/dev/null 2>&1 || {
    echo "[x11] Instalando Termux:X11..."
    pkg install -y termux-x11 2>/dev/null || true
}

echo "[x11] Iniciando Termux:X11..."
termux-x11 :0 -ac &
sleep 3
# Abre o app Termux:X11 automaticamente na tela
am start -n com.termux.x11/.MainActivity 2>/dev/null || true

echo "[arch] Iniciando Arch Linux + i3..."
echo "      Termux:X11 aberto automaticamente."
echo "      Pressione Ctrl+C para parar."

export PULSE_SERVER=127.0.0.1

# Auto-start Arch MCP Server se instalado
if [ -f "${HOME}/.arch-mcp/start.sh" ]; then
    echo "[mcp] Iniciando Arch MCP Server..."
    bash "${HOME}/.arch-mcp/start.sh" || echo "[mcp] AVISO: falha ao iniciar (veja ~/.arch-mcp/mcp.log)"
fi

# Entra no proot com forwarding de áudio + GPU + X11
proot-distro login archlinux \
    --termux-home \
    --shared-tmp \
    -- bash -c "
        export DISPLAY=:0
        export PULSE_SERVER=127.0.0.1
        export QT_STYLE_OVERRIDE=kvantum
        export QT_QPA_PLATFORMTHEME=qt5ct
        export MESA_NO_ERROR=1
        export MESA_GL_VERSION_OVERRIDE=4.6
        export GALLIUM_DRIVER=zink
        export MESA_LOADER_DRIVER_OVERRIDE=zink
        export TU_DEBUG=noconform
        export MESA_VK_WSI_PRESENT_MODE=immediate
        export ZINK_DESCRIPTORS=lazy

        # Força 1080p (S20 Ultra é 1440x3200, drena GPU no proot)
        xrandr -s 1920x1080 2>/dev/null || true

        # Atualiza configs do repo (pull incremental, ignora se sem internet)
        if [ -d /tmp/dotfiles-configs/.git ]; then
            cd /tmp/dotfiles-configs && git pull --depth 1 --ff-only 2>/dev/null || true
        else
            rm -rf /tmp/dotfiles-configs 2>/dev/null
            git clone --depth 1 https://github.com/emmanuelcandido/dotfiles.git /tmp/dotfiles-configs 2>/dev/null
        fi
        if [ -f /tmp/dotfiles-configs/arch-on-android/configs/i3/config ]; then
            mkdir -p \"$HOME/.config/i3\" \"$HOME/.config/polybar/scripts\" \
                     \"$HOME/.config/dunst\" \"$HOME/.config/rofi\" \
                     \"$HOME/.config/alacritty\" \"$HOME/.config/scripts\" \
                     \"$HOME/.config/wallpapers\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/i3/config                      \"$HOME/.config/i3/config\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/polybar/config.ini             \"$HOME/.config/polybar/config.ini\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/polybar/scripts/updates.sh     \"$HOME/.config/polybar/scripts/updates.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/polybar/scripts/spotify.sh     \"$HOME/.config/polybar/scripts/spotify.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/polybar/scripts/ticker-crypto.sh \"$HOME/.config/polybar/scripts/ticker-crypto.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/dunst/dunstrc                  \"$HOME/.config/dunst/dunstrc\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/rofi/config.rasi               \"$HOME/.config/rofi/config.rasi\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/alacritty/alacritty.yml        \"$HOME/.config/alacritty/alacritty.yml\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/scripts/power.sh               \"$HOME/.config/scripts/power.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/scripts/arch-update.sh         \"$HOME/.config/scripts/arch-update.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/scripts/proot-aliases.sh       \"$HOME/.config/scripts/proot-aliases.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/scripts/earlyoom-proot.sh     \"$HOME/.config/scripts/earlyoom-proot.sh\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/wallpapers/0010.png            \"$HOME/.config/wallpapers/0010.png\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/zsh/zshrc                      \"$HOME/.zshrc\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/starship/starship.toml         \"$HOME/.config/starship.toml\"
            cp /tmp/dotfiles-configs/arch-on-android/configs/urxvt/Xresources              \"$HOME/.Xresources\"
            chmod +x \"$HOME/.config/polybar/scripts/updates.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/polybar/scripts/spotify.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/polybar/scripts/ticker-crypto.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/scripts/power.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/scripts/arch-update.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/scripts/proot-aliases.sh\" 2>/dev/null
            chmod +x \"$HOME/.config/scripts/earlyoom-proot.sh\" 2>/dev/null
            # Cria alias arch-update se nao existir
            grep -q \"arch-update\" \"$HOME/.bashrc\" 2>/dev/null || {
                echo \"alias arch-update='$HOME/.config/scripts/arch-update.sh'\" >> \"$HOME/.bashrc\"
            }
            # Source proot-aliases no .bashrc se nao existir
            grep -q \"proot-aliases\" \"$HOME/.bashrc\" 2>/dev/null || {
                echo \"\" >> \"$HOME/.bashrc\"
                echo \"# ── Proot Aliases ──\" >> \"$HOME/.bashrc\"
                echo \"if [ -f \\\"\\$HOME/.config/scripts/proot-aliases.sh\\\" ]; then\" >> \"$HOME/.bashrc\"
                echo \"  source \\\"\\$HOME/.config/scripts/proot-aliases.sh\\\"\" >> \"$HOME/.bashrc\"
                echo \"fi\" >> \"$HOME/.bashrc\"
            }
            # Cria symlink no PATH se possivel
            ln -sf \"$HOME/.config/scripts/arch-update.sh\" /usr/local/bin/arch-update 2>/dev/null || true
            # Atualiza cache de icones Nordzy
            gtk-update-icon-cache /usr/share/icons/Nordzy 2>/dev/null || true
            # Define Nordzy como tema de icone padrao do sistema
            mkdir -p \"\$HOME/.config/gtk-3.0\" \"\$HOME/.config/gtk-4.0\"
            printf '[Settings]\\ngtk-icon-theme-name=Nordzy\\ngtk-theme-name=Nordic\\ngtk-font-name=Noto Sans 10\\n' > \"\$HOME/.config/gtk-3.0/settings.ini\"
            cp \"\$HOME/.config/gtk-3.0/settings.ini\" \"\$HOME/.config/gtk-4.0/settings.ini\" 2>/dev/null || true
        fi
        rm -rf /tmp/dotfiles-configs

        # Seta wallpaper (nord solid)
        command -v xsetroot >/dev/null 2>&1 || pacman -S --noconfirm xorg-xsetroot >/dev/null 2>&1
        xsetroot -solid '#2E3440' 2>/dev/null || true

        # Carrega config do URxvt
        command -v xrdb >/dev/null 2>&1 || pacman -S --noconfirm xorg-xrdb >/dev/null 2>&1
        [ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources" 2>/dev/null || true

	        # Reduce OOM score do proot (menos chance de ser morto pelo Android)
	        echo -500 > /proc/self/oom_score_adj 2>/dev/null || true

	        # Mata orphans dentro do proot (memoria baixa = OOM killer)
	        pkill -f "[e]lectron" 2>/dev/null || true
	        pkill -f "[c]hrome" 2>/dev/null || true

	        # Inicia earlyoom watchdog em background (mata apps antes do Android matar o proot)
	        if [ -f "$HOME/.config/scripts/earlyoom-proot.sh" ]; then
	            bash "$HOME/.config/scripts/earlyoom-proot.sh" &
	        fi

	        # Inicia i3
	        exec i3 2>/dev/null || exec i3-wm
    "
STARTEOF
    chmod +x "${BIN_DIR}/start-arch"

    # ── stop-arch ──
    cat > "${BIN_DIR}/stop-arch" << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
# stop-arch — Para sessão Arch + limpa processos
echo "Parando ArchDroid..."
pkill -9 -f "proot-distro login archlinux" 2>/dev/null
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "picom" 2>/dev/null
termux-wake-unlock 2>/dev/null || true
echo "ArchDroid parado."
STOPEOF
    chmod +x "${BIN_DIR}/stop-arch"

    # ── apply-configs ──
    cat > "${BIN_DIR}/apply-configs" << 'CONFIGSEOF'
#!/data/data/com.termux/files/usr/bin/bash
# apply-configs — Baixa e aplica dotfiles do repo no Arch proot
# Uso: apply-configs
# Nota: O start-arch já faz isso automaticamente.

REPO_URL="https://github.com/emmanuelcandido/dotfiles.git"
TMP_REPO="${HOME}/.cache/apply-configs/dotfiles"

echo "Baixando configs do repositório..."
rm -rf "$TMP_REPO" 2>/dev/null
if ! git clone --depth 1 "$REPO_URL" "$TMP_REPO"; then
    echo "ERRO: git clone falhou."
    echo "Comando manual: git clone --depth 1 $REPO_URL $TMP_REPO"
    exit 1
fi

echo "Copiando configs..."
mkdir -p "$HOME/.config/i3" "$HOME/.config/polybar/scripts" "$HOME/.config/dunst" "$HOME/.config/rofi" "$HOME/.config/alacritty" "$HOME/.config/scripts" "$HOME/.config/wallpapers"
cp "$TMP_REPO/arch-on-android/configs/i3/config"                      "$HOME/.config/i3/config" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/polybar/config.ini"             "$HOME/.config/polybar/config.ini" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/polybar/scripts/updates.sh"     "$HOME/.config/polybar/scripts/updates.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/polybar/scripts/spotify.sh"     "$HOME/.config/polybar/scripts/spotify.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/polybar/scripts/ticker-crypto.sh" "$HOME/.config/polybar/scripts/ticker-crypto.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/dunst/dunstrc"                  "$HOME/.config/dunst/dunstrc" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/rofi/config.rasi"               "$HOME/.config/rofi/config.rasi" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/alacritty/alacritty.yml"        "$HOME/.config/alacritty/alacritty.yml" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/scripts/power.sh"               "$HOME/.config/scripts/power.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/scripts/arch-update.sh"         "$HOME/.config/scripts/arch-update.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/scripts/proot-aliases.sh"       "$HOME/.config/scripts/proot-aliases.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/scripts/earlyoom-proot.sh"     "$HOME/.config/scripts/earlyoom-proot.sh" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/wallpapers/0010.png"            "$HOME/.config/wallpapers/0010.png" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/zsh/zshrc"                      "$HOME/.zshrc" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/starship/starship.toml"         "$HOME/.config/starship.toml" 2>/dev/null
cp "$TMP_REPO/arch-on-android/configs/urxvt/Xresources"              "$HOME/.Xresources" 2>/dev/null

chmod +x "$HOME/.config/polybar/scripts/updates.sh" 2>/dev/null
chmod +x "$HOME/.config/polybar/scripts/spotify.sh" 2>/dev/null
chmod +x "$HOME/.config/polybar/scripts/ticker-crypto.sh" 2>/dev/null
chmod +x "$HOME/.config/scripts/power.sh" 2>/dev/null
chmod +x "$HOME/.config/scripts/arch-update.sh" 2>/dev/null
chmod +x "$HOME/.config/scripts/proot-aliases.sh" 2>/dev/null
chmod +x "$HOME/.config/scripts/earlyoom-proot.sh" 2>/dev/null

# Garante que .bashrc source os aliases VPS
grep -q "proot-aliases" "$HOME/.bashrc" 2>/dev/null || {
    echo "" >> "$HOME/.bashrc"
    echo "# ── Proot Aliases ──" >> "$HOME/.bashrc"
    echo 'if [ -f "$HOME/.config/scripts/proot-aliases.sh" ]; then' >> "$HOME/.bashrc"
    echo '  source "$HOME/.config/scripts/proot-aliases.sh"' >> "$HOME/.bashrc"
    echo 'fi' >> "$HOME/.bashrc"
}

rm -rf "$TMP_REPO"
echo "Configs aplicadas! Reinicie o i3: Mod+Shift+R"
CONFIGSEOF
    chmod +x "${BIN_DIR}/apply-configs"

    # ── uninstall-arch ──
    cat > "${BIN_DIR}/uninstall-arch" << 'UNINSTALLEOF'
#!/data/data/com.termux/files/usr/bin/bash
# uninstall-arch — Remove Arch Linux + scripts completamente
echo "AVISO: Isso vai remover todo o Arch Linux e configurações!"
echo "       Dados em ~/archroid-backup/ serão preservados se existirem."
read -rp "Tem certeza? (yes/N): " confirm
[ "$confirm" != "yes" ] && echo "Cancelado." && exit 1

echo "Removendo Arch Linux..."
"${HOME}/stop-arch" 2>/dev/null || true
proot-distro remove archlinux 2>/dev/null || true

echo "Removendo scripts..."
rm -f "${HOME}/start-arch" "${HOME}/stop-arch" "${HOME}/uninstall-arch"

echo "Arch Linux removido. Reinstale com: bash setup-archroid.sh"
UNINSTALLEOF
    chmod +x "${BIN_DIR}/uninstall-arch"

    # Adiciona ao PATH se não existir
    if ! grep -q "local/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    if ! grep -q "local/bin" ~/.zshrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
    fi

    # Symlinks direto no ~ também para acesso fácil
    ln -sf "${BIN_DIR}/start-arch" "${HOME}/start-arch"
    ln -sf "${BIN_DIR}/stop-arch" "${HOME}/stop-arch"
    ln -sf "${BIN_DIR}/uninstall-arch" "${HOME}/uninstall-arch"
    ln -sf "${BIN_DIR}/apply-configs" "${HOME}/apply-configs"

    # ── start-arch-cli ──
    cat > "${BIN_DIR}/start-arch-cli" << 'CLIEOF'
#!/data/data/com.termux/files/usr/bin/bash
# start-arch-cli — Apenas login no Arch (sem X11)
export PULSE_SERVER=127.0.0.1
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy

exec proot-distro login archlinux --termux-home --shared-tmp
CLIEOF
    chmod +x "${BIN_DIR}/start-arch-cli"

    # ── start-kde ──
    cat > "${BIN_DIR}/start-kde" << 'KDEEOF'
#!/data/data/com.termux/files/usr/bin/bash
# start-kde — Inicia Arch Linux + KDE Plasma via Termux:X11

termux-wake-lock 2>/dev/null || true

export DISPLAY=:0

# GPU config
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy

# Mata orphans Electron/Chromium que acumulam memoria (OOM killer prevention)
pkill -f "shm-helper" 2>/dev/null || true
pkill -f "[e]lectron" 2>/dev/null || true

cleanup() {
    echo "Parando sessão..."
    pkill -9 -f "termux.x11" 2>/dev/null
    pkill -9 -f "pulseaudio" 2>/dev/null
    termux-wake-unlock 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Inicia PulseAudio
pulseaudio --check 2>/dev/null || {
    echo "[audio] Iniciando PulseAudio..."
    env -u PULSE_SERVER pulseaudio --start --exit-idle-time=-1
    sleep 1
    pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
}

# Instala Termux:X11 se não existir
command -v termux-x11 >/dev/null 2>&1 || {
    echo "[x11] Instalando Termux:X11..."
    pkg install -y termux-x11 2>/dev/null || true
}

echo "[x11] Iniciando Termux:X11..."
termux-x11 :0 -ac &
sleep 3

echo "[kde] Iniciando Arch Linux + KDE Plasma..."
echo "      Abra o app Termux:X11 para ver o desktop."
echo "      Pressione Ctrl+C para parar."

proot-distro login archlinux \
    --termux-home \
    --shared-tmp \
    -- bash -c "
        export DISPLAY=:0
        export PULSE_SERVER=127.0.0.1
        export QT_STYLE_OVERRIDE=kvantum
        export QT_QPA_PLATFORMTHEME=qt5ct
        export MESA_NO_ERROR=1
        export MESA_GL_VERSION_OVERRIDE=4.6
        export GALLIUM_DRIVER=zink
        export MESA_LOADER_DRIVER_OVERRIDE=zink
        export TU_DEBUG=noconform
        export MESA_VK_WSI_PRESENT_MODE=immediate
        export ZINK_DESCRIPTORS=lazy
        export DESKTOP_SESSION=plasma
        export XDG_SESSION_DESKTOP=KDE
        export XDG_CURRENT_DESKTOP=KDE

        # Reduce OOM score do proot (menos chance de ser morto pelo Android)
        echo -500 > /proc/self/oom_score_adj 2>/dev/null || true

        # Mata orphans dentro do proot
        pkill -f "[e]lectron" 2>/dev/null || true
        pkill -f "[c]hrome" 2>/dev/null || true

        # Inicia earlyoom watchdog em background
        if [ -f "$HOME/.config/scripts/earlyoom-proot.sh" ]; then
            bash "$HOME/.config/scripts/earlyoom-proot.sh" &
        fi

        exec startplasma-x11 2>/dev/null
    "
KDEEOF
    chmod +x "${BIN_DIR}/start-kde"

    # ── VPS Aliases (Termux-level, fora do proot) ──
    for _cmd in vps-shell vps-tmux vps-tmux-kill vps-claude vps-claude-safe vps-claude-resume vps-claude-safe-resume vps-cc-or vps-pi vps-pi-coder vps-herdr vps-deploy vps-logs ccgram-restart; do
        case "$_cmd" in
            vps-shell)
                cat > "${BIN_DIR}/vps-shell" << 'VPSSHELL'
#!/data/data/com.termux/files/usr/bin/bash
# vps-shell — Shell direto na VPS (via mosh), já dentro de /root/lifeos (04/09)
exec mosh root@lifeosdev.duckdns.org -- bash -c 'cd /root/lifeos && exec bash -i'
VPSSHELL
                ;;
            vps-tmux)
                cat > "${BIN_DIR}/vps-tmux" << 'VPSTMUX'
#!/data/data/com.termux/files/usr/bin/bash
# vps-tmux — Menu interativo tmux na VPS (via mosh)
# Lista, anexa, cria e encerra sessões
exec mosh root@lifeosdev.duckdns.org -- bash /root/lifeos/infra/scripts/tmux-menu.sh
VPSTMUX
                ;;
            vps-tmux-kill)
                cat > "${BIN_DIR}/vps-tmux-kill" << 'VPSTKILL'
#!/data/data/com.termux/files/usr/bin/bash
# vps-tmux-kill — Encerra janela tmux na VPS (via mosh)
exec mosh root@lifeosdev.duckdns.org -- bash /root/lifeos/infra/scripts/tmux-menu.sh kill
VPSTKILL
                ;;
            vps-claude)
                cat > "${BIN_DIR}/vps-claude" << 'VPSCLAUDE'
#!/data/data/com.termux/files/usr/bin/bash
# vps-claude — Mosh + claude YOLO (IS_SANDBOX=1, sem permissões) no repo principal
exec mosh root@lifeosdev.duckdns.org -- bash -c "cd /root/lifeos && IS_SANDBOX=1 claude --dangerously-skip-permissions"
VPSCLAUDE
                ;;
            vps-claude-safe)
                cat > "${BIN_DIR}/vps-claude-safe" << 'VPSCLAUDESAFE'
#!/data/data/com.termux/files/usr/bin/bash
# vps-claude-safe — Mosh + claude COM permissões (modo normal)
exec mosh root@lifeosdev.duckdns.org -- bash -c "cd /root/lifeos && claude"
VPSCLAUDESAFE
                ;;
            vps-claude-resume)
                cat > "${BIN_DIR}/vps-claude-resume" << 'VPSCLAUDERESUME'
#!/data/data/com.termux/files/usr/bin/bash
# vps-claude-resume — Mosh + claude YOLO com menu de resume no repo principal
exec mosh root@lifeosdev.duckdns.org -- bash -c "cd /root/lifeos && IS_SANDBOX=1 claude --dangerously-skip-permissions --resume"
VPSCLAUDERESUME
                ;;
            vps-claude-safe-resume)
                cat > "${BIN_DIR}/vps-claude-safe-resume" << 'VPSCLAUDESAFERESUME'
#!/data/data/com.termux/files/usr/bin/bash
# vps-claude-safe-resume — Mosh + claude COM permissões + menu de resume
exec mosh root@lifeosdev.duckdns.org -- bash -c "cd /root/lifeos && claude --resume"
VPSCLAUDESAFERESUME
                ;;
            vps-cc-or)
                cat > "${BIN_DIR}/vps-cc-or" << 'VPSCCOR'
#!/data/data/com.termux/files/usr/bin/bash
# vps-cc-or — Claude Code via OpenRouter NA VPS (função cc-or do ~/.bash_aliases), sempre em /root/lifeos (04/09)
exec mosh root@lifeosdev.duckdns.org -- bash -c 'cd /root/lifeos && . ~/.bash_aliases && cc-or "$@"' _ "$@"
VPSCCOR
                ;;
            vps-pi)
                cat > "${BIN_DIR}/vps-pi" << 'VPSPI'
#!/data/data/com.termux/files/usr/bin/bash
# vps-pi — Pi (perfil founder) NA VPS, sempre em /root/lifeos (04/09)
exec mosh root@lifeosdev.duckdns.org -- bash -c 'cd /root/lifeos && . ~/.bash_aliases && pi "$@"' _ "$@"
VPSPI
                ;;
            vps-pi-coder)
                cat > "${BIN_DIR}/vps-pi-coder" << 'VPSPICODER'
#!/data/data/com.termux/files/usr/bin/bash
# vps-pi-coder — Pi (perfil coder isolado) NA VPS, sempre em /root/lifeos (04/09)
exec mosh root@lifeosdev.duckdns.org -- bash -c 'cd /root/lifeos && . ~/.bash_aliases && pi-coder "$@"' _ "$@"
VPSPICODER
                ;;
            vps-herdr)
                cat > "${BIN_DIR}/vps-herdr" << 'VPSHERDR'
#!/data/data/com.termux/files/usr/bin/bash
# vps-herdr — Anexa a sessão herdr (tmux herdr-coder) NA VPS (04/09)
exec mosh root@lifeosdev.duckdns.org -- tmux attach -t herdr-coder
VPSHERDR
                ;;
            vps-deploy)
                cat > "${BIN_DIR}/vps-deploy" << 'VPSDEPLOY'
#!/data/data/com.termux/files/usr/bin/bash
# vps-deploy — Mosh + git pull + deploy
exec mosh root@lifeosdev.duckdns.org -- bash -c "cd /opt/infra && git pull && sudo bash deploy.sh"
VPSDEPLOY
                ;;
            vps-logs)
                cat > "${BIN_DIR}/vps-logs" << 'VPSLOGS'
#!/data/data/com.termux/files/usr/bin/bash
# vps-logs — Mosh + journalctl tail
exec mosh root@lifeosdev.duckdns.org -- journalctl -f -n 50
VPSLOGS
                ;;
            ccgram-restart)
                cat > "${BIN_DIR}/ccgram-restart" << 'CCGRAMRST'
#!/data/data/com.termux/files/usr/bin/bash
# ccgram-restart — Reinicia o bot ccgram na VPS
exec mosh root@lifeosdev.duckdns.org -- systemctl restart ccgram.service
CCGRAMRST
                ;;
        esac
        chmod +x "${BIN_DIR}/${_cmd}"
    done

    # Symlinks
    ln -sf "${BIN_DIR}/start-kde" "${HOME}/start-kde"
    ln -sf "${BIN_DIR}/start-arch-cli" "${HOME}/start-arch-cli"
    for _cmd in vps-shell vps-tmux vps-tmux-kill vps-claude vps-claude-safe vps-claude-resume vps-claude-safe-resume vps-cc-or vps-pi vps-pi-coder vps-herdr vps-deploy vps-logs ccgram-restart; do
        ln -sf "${BIN_DIR}/${_cmd}" "${HOME}/${_cmd}"
    done

    echo "[aliases] Comandos criados: start-arch, start-arch-cli, start-kde, stop-arch, uninstall-arch, apply-configs, vps-* (14: shell/tmux/claude/cc-or/pi/pi-coder/herdr/deploy/logs), ccgram-restart"
}

# Execução direta: `bash setup-aliases.sh` instala/atualiza tudo (idempotente — 04/09)
# Quando sourceado (apply-configs.sh / setup-archroid.sh), só define a função.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_aliases
fi
