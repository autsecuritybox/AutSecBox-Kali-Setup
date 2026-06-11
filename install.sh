#!/usr/bin/env bash
# =============================================================================
# AutSecurity Box - Kali Linux Environment Setup
# Version: 2.0
# Author: AutSecurity Team
# Description: Script de instalacion completo para entorno de pentesting CTF
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# COLORES Y ESTILOS
# ---------------------------------------------------------------------------
RED='\033[38;2;233;69;96m'
ORANGE='\033[38;2;255;107;53m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# VARIABLES GLOBALES
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
CONFIG_DIR="$HOME_DIR/.config"
LOG_FILE="/tmp/autsecurity_install_$(date +%Y%m%d_%H%M%S).log"
DOTFILES_DIR="$HOME_DIR/.dotfiles"
FONTS_DIR="$HOME_DIR/.local/share/fonts"
WALLPAPERS_DIR="$HOME_DIR/.local/share/wallpapers"
CURRENT_USER=$(whoami)
ERRORS=0

# ---------------------------------------------------------------------------
# FUNCIONES DE LOGGING Y UI
# ---------------------------------------------------------------------------
log() { echo -e "$1" | tee -a "$LOG_FILE"; }

banner() {
    clear
    log "${RED}"
    log "  █████╗ ██╗   ██╗████████╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗"
    log " ██╔══██╗██║   ██║╚══██╔══╝██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝"
    log " ███████║██║   ██║   ██║   ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝ "
    log " ██╔══██║██║   ██║   ██║   ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝  "
    log " ██║  ██║╚██████╔╝   ██║   ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║   "
    log " ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝  "
    log "${ORANGE}"
    log "                    ██████╗  ██████╗ ██╗  ██╗"
    log "                    ██╔══██╗██╔═══██╗╚██╗██╔╝"
    log "                    ██████╔╝██║   ██║ ╚███╔╝ "
    log "                    ██╔══██╗██║   ██║ ██╔██╗ "
    log "                    ██████╔╝╚██████╔╝██╔╝ ██╗"
    log "                    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝"
    log "${NC}"
    log "${DIM}${WHITE}              CTF & Pentesting Environment Installer v2.0.0${NC}"
    log "${DIM}                    Kali Linux | bspwm | Polybar | Zsh${NC}"
    log ""
}

step()    { log "\n${BOLD}${CYAN}[*]${NC} ${BOLD}$1${NC}"; }
ok()      { log "${GREEN}[+]${NC} $1"; }
warn()    { log "${ORANGE}[!]${NC} $1"; }
err()     { log "${RED}[-]${NC} $1"; ERRORS=$((ERRORS + 1)); }
section() { log "\n${RED}${BOLD}══════════════════════════════════════════${NC}"; log "${RED}${BOLD}  $1${NC}"; log "${RED}${BOLD}══════════════════════════════════════════${NC}"; }

run() {
    local desc="$1"
    shift
    step "$desc"
    if "$@" >> "$LOG_FILE" 2>&1; then
        ok "Completado: $desc"
    else
        err "Fallo: $desc (ver $LOG_FILE)"
    fi
}

ask_confirm() {
    local prompt="$1"
    local response
    echo -ne "${ORANGE}[?]${NC} ${prompt} [s/N]: "
    read -r response
    [[ "$response" =~ ^[sS]$ ]]
}

# ---------------------------------------------------------------------------
# VALIDACIONES PREVIAS
# ---------------------------------------------------------------------------
check_kali() {
    section "VALIDACION DEL SISTEMA"
    step "Verificando distribucion Linux..."
    if [[ ! -f /etc/os-release ]]; then
        err "No se puede determinar la distribucion. Abortando."
        exit 1
    fi
    source /etc/os-release
    if [[ "${ID}" != "kali" ]]; then
        warn "Este script esta optimizado para Kali Linux."
        warn "Distribucion detectada: ${PRETTY_NAME}"
        if ! ask_confirm "Continuar de todas formas?"; then
            log "Instalacion cancelada por el usuario."
            exit 0
        fi
    else
        ok "Kali Linux detectado: ${PRETTY_NAME}"
    fi
}

check_root() {
    step "Verificando permisos..."
    if [[ "$EUID" -eq 0 ]]; then
        err "No ejecutes este script como root. Usa tu usuario normal con sudo disponible."
        exit 1
    fi
    if ! sudo -n true 2>/dev/null; then
        warn "Se necesitaran privilegios sudo durante la instalacion."
        sudo -v || { err "No se pudo obtener privilegios sudo."; exit 1; }
    fi
    ok "Usuario: $CURRENT_USER | Sudo: disponible"
}

check_internet() {
    step "Verificando conectividad a internet..."
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        err "Sin conexion a internet. Verifica tu red."
        exit 1
    fi
    ok "Conectividad OK"
}

check_disk_space() {
    step "Verificando espacio en disco..."
    local available_gb
    available_gb=$(df -BG "$HOME" | awk 'NR==2 {gsub("G",""); print $4}')
    if [[ "$available_gb" -lt 10 ]]; then
        warn "Espacio disponible: ${available_gb}GB. Se recomiendan al menos 10GB."
        if ! ask_confirm "Continuar con poco espacio?"; then
            exit 0
        fi
    else
        ok "Espacio disponible: ${available_gb}GB"
    fi
}

# ---------------------------------------------------------------------------
# IDEMPOTENCIA: verificar si algo ya esta instalado
# ---------------------------------------------------------------------------
is_installed() { command -v "$1" &>/dev/null; }
pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q '^ii'; }
dir_exists()  { [[ -d "$1" ]]; }

# ---------------------------------------------------------------------------
# ACTUALIZACION DEL SISTEMA
# ---------------------------------------------------------------------------
update_system() {
    section "ACTUALIZACION DEL SISTEMA"
    step "Actualizando repositorios y paquetes..."
    sudo apt-get update -qq >> "$LOG_FILE" 2>&1 && ok "Repositorios actualizados" || warn "Problemas actualizando repositorios"
    sudo apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1 && ok "Paquetes actualizados" || warn "Algunos paquetes no actualizados (continuando)"
    local base_pkgs=(
        curl wget git unzip zip tar
        build-essential cmake pkg-config
        python3 python3-pip python3-venv pipx
        libssl-dev libffi-dev libxml2-dev libxslt1-dev
        zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
        software-properties-common apt-transport-https
        gnupg2 ca-certificates lsb-release
        xorg xserver-xorg xinit
        imagemagick librsvg2-bin
    )
    for pkg in "${base_pkgs[@]}"; do
        sudo apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1 || warn "Paquete base no disponible: $pkg"
    done
    ok "Dependencias base instaladas"
}

# ---------------------------------------------------------------------------
# FUENTES NERD FONTS
# ---------------------------------------------------------------------------
install_fonts() {
    section "INSTALACION DE FUENTES"
    mkdir -p "$FONTS_DIR"

    local fonts=(
        "Hack"
        "JetBrainsMono"
        "FiraCode"
        "Meslo"
        "SourceCodePro"
    )

    for font in "${fonts[@]}"; do
        if find "$FONTS_DIR" -iname "${font}*.ttf" 2>/dev/null | grep -q .; then
            ok "Fuente $font ya instalada, omitiendo."
            continue
        fi
        step "Instalando Nerd Font: $font"
        local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font}.zip"
        local tmp="/tmp/${font}.zip"
        if wget -q "$url" -O "$tmp" >> "$LOG_FILE" 2>&1; then
            unzip -q -o "$tmp" -d "$FONTS_DIR/" >> "$LOG_FILE" 2>&1
            rm -f "$tmp"
            ok "$font instalada"
        else
            err "No se pudo descargar $font"
        fi
    done

    fc-cache -fv >> "$LOG_FILE" 2>&1 || warn "fc-cache tuvo un error (las fuentes cargarán tras reiniciar)"
    ok "Cache de fuentes actualizado"
}

# ---------------------------------------------------------------------------
# WINDOW MANAGER: bspwm + sxhkd
# ---------------------------------------------------------------------------
install_wm() {
    section "WINDOW MANAGER: bspwm + sxhkd"

    local pkgs=(
        bspwm sxhkd
        picom
        rofi
        polybar
        feh
        dunst
        kitty
        xdotool xdg-utils
        lxappearance
        arandr autorandr
        flameshot maim
        xclip xsel
        wmctrl
        libnotify-bin
        i3lock
    )

    step "Instalando paquetes del entorno grafico..."
    local failed_pkgs=()
    for pkg in "${pkgs[@]}"; do
        if ! sudo apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1; then
            warn "Paquete no disponible: $pkg (omitiendo)"
            failed_pkgs+=("$pkg")
        fi
    done
    if [[ ${#failed_pkgs[@]} -eq 0 ]]; then
        ok "Paquetes WM instalados"
    else
        warn "Paquetes WM instalados con excepciones: ${failed_pkgs[*]}"
    fi
}

# ---------------------------------------------------------------------------
# TERMINAL: Alacritty
# ---------------------------------------------------------------------------
install_alacritty() {
    section "TERMINAL: Alacritty"

    if is_installed alacritty; then
        ok "Alacritty ya esta instalado."
        return
    fi

    step "Instalando Alacritty via apt..."
    if sudo apt-get install -y -qq alacritty >> "$LOG_FILE" 2>&1; then
        ok "Alacritty instalado desde repositorio"
        return
    fi

    step "Compilando Alacritty desde fuente (fallback)..."
    sudo apt-get install -y -qq \
        cmake pkg-config libfreetype6-dev libfontconfig1-dev \
        libxcb-xfixes0-dev libxkbcommon-dev python3 \
        cargo >> "$LOG_FILE" 2>&1

    if ! dir_exists "/tmp/alacritty-src"; then
        git clone https://github.com/alacritty/alacritty.git /tmp/alacritty-src >> "$LOG_FILE" 2>&1
    fi

    pushd /tmp/alacritty-src > /dev/null
    cargo build --release >> "$LOG_FILE" 2>&1
    sudo cp target/release/alacritty /usr/local/bin/
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop >> "$LOG_FILE" 2>&1
    sudo update-desktop-database >> "$LOG_FILE" 2>&1
    popd > /dev/null
    ok "Alacritty compilado e instalado"
}

# ---------------------------------------------------------------------------
# SHELL: Zsh + Oh My Zsh + Powerlevel10k
# ---------------------------------------------------------------------------
install_shell() {
    section "SHELL: Zsh + Oh My Zsh + Powerlevel10k"

    step "Instalando Zsh..."
    sudo apt-get install -y -qq zsh >> "$LOG_FILE" 2>&1
    ok "Zsh instalado"

    if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
        step "Instalando Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >> "$LOG_FILE" 2>&1
        ok "Oh My Zsh instalado"
    else
        ok "Oh My Zsh ya instalado, omitiendo."
    fi

    local ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"

    # Plugins
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "Aloxaf/fzf-tab"
        "zsh-users/zsh-history-substring-search"
    )

    for plugin_repo in "${plugins[@]}"; do
        local plugin_name="${plugin_repo##*/}"
        local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"
        if ! dir_exists "$plugin_dir"; then
            step "Instalando plugin: $plugin_name"
            git clone --depth=1 "https://github.com/${plugin_repo}.git" "$plugin_dir" >> "$LOG_FILE" 2>&1
            ok "$plugin_name instalado"
        else
            ok "Plugin $plugin_name ya existe, omitiendo."
        fi
    done

    # Powerlevel10k
    local p10k_dir="$ZSH_CUSTOM/themes/powerlevel10k"
    if ! dir_exists "$p10k_dir"; then
        step "Instalando tema Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >> "$LOG_FILE" 2>&1
        ok "Powerlevel10k instalado"
    else
        ok "Powerlevel10k ya instalado, omitiendo."
    fi

    # Cambiar shell por defecto
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        step "Configurando Zsh como shell por defecto..."
        sudo chsh -s "$(which zsh)" "$CURRENT_USER" >> "$LOG_FILE" 2>&1
        ok "Zsh configurado como shell por defecto"
    fi
}

# ---------------------------------------------------------------------------
# FZF
# ---------------------------------------------------------------------------
install_fzf() {
    section "FZF - Fuzzy Finder"
    if is_installed fzf; then
        ok "fzf ya instalado."
        return
    fi
    if ! dir_exists "$HOME_DIR/.fzf"; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME_DIR/.fzf" >> "$LOG_FILE" 2>&1
    fi
    "$HOME_DIR/.fzf/install" --all --no-bash --no-fish >> "$LOG_FILE" 2>&1
    ok "fzf instalado"
}

# ---------------------------------------------------------------------------
# HERRAMIENTAS DE PENTESTING
# ---------------------------------------------------------------------------
install_pentesting_tools() {
    section "HERRAMIENTAS DE PENTESTING"

    # Paquetes apt disponibles en Kali
    local apt_tools=(
        nmap masscan
        gobuster ffuf feroxbuster
        metasploit-framework
        bloodhound neo4j
        crackmapexec
        evil-winrm
        john hashcat hashid
        seclists
        whatweb
        enum4linux
        sqlmap
        nikto
        wireshark-qt tcpdump
        aircrack-ng wifite kismet
        hydra medusa
        netcat-openbsd socat
        python3-impacket
        responder
        bettercap
        theharvester
        maltego
        wordlists
        dirbuster
        wpscan
        nuclei
        amass
        subfinder
        httpx-toolkit
        dnsx
        katana
        net-tools dnsutils whois
        p7zip-full rar unrar
        jq yq
        tmux screen
        bat fd-find ripgrep
        htop btop
        vim neovim
        firefox-esr
        burpsuite
    )

    step "Instalando herramientas de pentesting via apt..."
    for tool in "${apt_tools[@]}"; do
        if ! pkg_installed "$tool"; then
            sudo apt-get install -y -qq "$tool" >> "$LOG_FILE" 2>&1 \
                && ok "Instalado: $tool" \
                || warn "No disponible via apt: $tool"
        else
            ok "Ya instalado: $tool"
        fi
    done

    # Herramientas via pip/pipx
    install_pip_tools

    # Herramientas manuales (binarios/go)
    install_go_tools
    install_manual_tools
}

install_pip_tools() {
    section "HERRAMIENTAS VIA PIP"
    local pip_tools=(
        "impacket"
        "ldapdomaindump"
        "certipy-ad"
        "pwntools"
        "requests"
        "beautifulsoup4"
        "pycryptodome"
        "netexec"
    )

    for tool in "${pip_tools[@]}"; do
        step "pip: $tool"
        pipx install "$tool" >> "$LOG_FILE" 2>&1 \
            && ok "pipx: $tool instalado" \
            || warn "pipx: fallo $tool (puede ya estar instalado)"
    done
}

install_go_tools() {
    section "HERRAMIENTAS VIA GO"

    if ! is_installed go; then
        step "Instalando Go..."
        local GO_VERSION="1.22.3"
        if wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz >> "$LOG_FILE" 2>&1; then
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz >> "$LOG_FILE" 2>&1
            export PATH=$PATH:/usr/local/go/bin
            ok "Go ${GO_VERSION} instalado"
        else
            warn "No se pudo descargar Go ${GO_VERSION}. Herramientas Go omitidas."
            return
        fi
    else
        ok "Go ya instalado: $(go version)"
    fi

    export GOPATH="$HOME_DIR/go"
    export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

    local go_tools=(
        "github.com/OJ/gobuster/v3@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/ropnop/kerbrute@latest"
        "github.com/ffuf/ffuf/v2@latest"
    )

    for tool in "${go_tools[@]}"; do
        step "go install: ${tool##*/}"
        go install "$tool" >> "$LOG_FILE" 2>&1 \
            && ok "Instalado: ${tool##*/}" \
            || warn "Fallo: ${tool##*/}"
    done
}

install_manual_tools() {
    section "HERRAMIENTAS MANUALES"
    local TOOLS_DIR="$HOME_DIR/tools"
    mkdir -p "$TOOLS_DIR"

    # Chisel
    if ! is_installed chisel; then
        step "Instalando Chisel..."
        local CHISEL_VER="1.9.1"
        if wget -q "https://github.com/jpillora/chisel/releases/download/v${CHISEL_VER}/chisel_${CHISEL_VER}_linux_amd64.gz" \
            -O /tmp/chisel.gz >> "$LOG_FILE" 2>&1; then
            gunzip -f /tmp/chisel.gz
            chmod +x /tmp/chisel
            sudo mv /tmp/chisel /usr/local/bin/chisel
            ok "Chisel instalado"
        else
            err "No se pudo descargar Chisel v${CHISEL_VER}"
        fi
    else
        ok "Chisel ya instalado"
    fi

    # Ligolo-ng
    if [[ ! -f "$TOOLS_DIR/ligolo-ng/proxy" ]]; then
        step "Instalando Ligolo-ng..."
        mkdir -p "$TOOLS_DIR/ligolo-ng"
        local LIGOLO_VER="0.6.2"
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/v${LIGOLO_VER}/ligolo-ng_proxy_${LIGOLO_VER}_linux_amd64.tar.gz" \
            -O /tmp/ligolo-proxy.tar.gz >> "$LOG_FILE" 2>&1
        tar -xzf /tmp/ligolo-proxy.tar.gz -C "$TOOLS_DIR/ligolo-ng/" >> "$LOG_FILE" 2>&1
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/v${LIGOLO_VER}/ligolo-ng_agent_${LIGOLO_VER}_linux_amd64.tar.gz" \
            -O /tmp/ligolo-agent.tar.gz >> "$LOG_FILE" 2>&1
        tar -xzf /tmp/ligolo-agent.tar.gz -C "$TOOLS_DIR/ligolo-ng/" >> "$LOG_FILE" 2>&1
        sudo ln -sf "$TOOLS_DIR/ligolo-ng/proxy" /usr/local/bin/ligolo-proxy
        ok "Ligolo-ng instalado en $TOOLS_DIR/ligolo-ng/"
    else
        ok "Ligolo-ng ya instalado"
    fi

    # Enum4linux-ng
    if ! is_installed enum4linux-ng; then
        step "Instalando enum4linux-ng..."
        git clone --depth=1 https://github.com/cddmp/enum4linux-ng.git "$TOOLS_DIR/enum4linux-ng" >> "$LOG_FILE" 2>&1
        sudo ln -sf "$TOOLS_DIR/enum4linux-ng/enum4linux-ng.py" /usr/local/bin/enum4linux-ng
        ok "enum4linux-ng instalado"
    else
        ok "enum4linux-ng ya instalado"
    fi

    # LinPEAS / WinPEAS
    if [[ ! -d "$TOOLS_DIR/PEASS-ng" ]]; then
        step "Clonando PEASS-ng (linPEAS/winPEAS)..."
        git clone --depth=1 https://github.com/carlospolop/PEASS-ng.git "$TOOLS_DIR/PEASS-ng" >> "$LOG_FILE" 2>&1
        ok "PEASS-ng clonado"
    fi

    # pspy
    if [[ ! -f "$TOOLS_DIR/pspy64" ]]; then
        step "Descargando pspy64..."
        wget -q "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64" \
            -O "$TOOLS_DIR/pspy64" >> "$LOG_FILE" 2>&1
        chmod +x "$TOOLS_DIR/pspy64"
        ok "pspy64 descargado"
    fi

    # Invoke-Obfuscation y otros PS
    if [[ ! -d "$TOOLS_DIR/PowerSploit" ]]; then
        step "Clonando PowerSploit..."
        git clone --depth=1 https://github.com/PowerShellMafia/PowerSploit.git "$TOOLS_DIR/PowerSploit" >> "$LOG_FILE" 2>&1
        ok "PowerSploit clonado"
    fi

    # SecLists (si no esta)
    if [[ ! -d "/usr/share/seclists" ]]; then
        step "Instalando SecLists..."
        sudo apt-get install -y -qq seclists >> "$LOG_FILE" 2>&1 \
            || {
                git clone --depth=1 https://github.com/danielmiessler/SecLists.git /tmp/seclists >> "$LOG_FILE" 2>&1
                sudo mv /tmp/seclists /usr/share/seclists
            }
        ok "SecLists instalado"
    else
        ok "SecLists ya instalado en /usr/share/seclists"
    fi

    # ─── Scripts de utilidad CTF ────────────────────────────────
    step "Instalando scripts CTF (extract-ports, xcopy, scope, xpaste)..."

    # extract-ports: parsea salida nmap grepable y copia puertos al clipboard
    cat > /usr/local/bin/extract-ports << 'EXTRACTEOF'
#!/usr/bin/env bash
RED='\033[38;2;233;69;96m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
if [[ -z "$1" || ! -f "$1" ]]; then echo -e "${RED}Uso: extract-ports <archivo.gnmap>${NC}"; exit 1; fi
ip=$(grep -oP '\d+\.\d+\.\d+\.\d+' "$1" | grep -v '127.0.0.1' | head -1)
ports=$(grep -oP '\d+/open' "$1" | cut -d/ -f1 | tr '\n' ',' | sed 's/,$//')
if [[ -z "$ports" ]]; then echo -e "${RED}[-] Sin puertos abiertos${NC}"; exit 1; fi
echo -e "${CYAN}───────────────────────────────────${NC}"
echo -e " ${GREEN}[*]${NC} IP     : $ip"
echo -e " ${GREEN}[*]${NC} Puertos: $ports"
echo -e "${CYAN}───────────────────────────────────${NC}"
echo -n "$ports" | xclip -sel clip 2>/dev/null || echo -n "$ports" | xsel --clipboard --input 2>/dev/null
echo -e " ${GREEN}[+]${NC} Copiado al clipboard"
EXTRACTEOF

    # xcopy: copia contenido de archivo al clipboard
    cat > /usr/local/bin/xcopy << 'XCOPYEOF'
#!/usr/bin/env bash
if [[ -z "$1" || ! -f "$1" ]]; then echo "Uso: xcopy <archivo>"; exit 1; fi
cat "$1" | xclip -sel clip 2>/dev/null || cat "$1" | xsel --clipboard --input
echo "[+] Copiado: $1"
XCOPYEOF

    # scope: gestiona targets activos para pentesting
    cat > /usr/local/bin/scope << 'SCOPEEOF'
#!/usr/bin/env bash
RED='\033[38;2;233;69;96m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
SCOPE_FILE="$HOME/.config/bin/scope"
mkdir -p "$(dirname "$SCOPE_FILE")"
[[ ! -f "$SCOPE_FILE" ]] && touch "$SCOPE_FILE"
case "$1" in
    add|-a)    shift; for t in "$@"; do grep -qxF "$t" "$SCOPE_FILE" && echo -e "${RED}[!]${NC} Ya existe: $t" || { echo "$t" >> "$SCOPE_FILE"; echo -e "${GREEN}[+]${NC} Agregado: $t"; }; done ;;
    remove|rm) shift; for t in "$@"; do escaped=$(printf '%s\n' "$t" | sed 's/[.[\*^$()+?{|]/\\&/g'); sed -i "/^${escaped}$/d" "$SCOPE_FILE"; echo -e "${RED}[-]${NC} Eliminado: $t"; done ;;
    clear|-c)  > "$SCOPE_FILE"; echo -e "${GREEN}[+]${NC} Scope vaciado" ;;
    list|-l|"") [[ ! -s "$SCOPE_FILE" ]] && echo -e "${RED}[!]${NC} Scope vacío" || { echo -e "${CYAN}[*]${NC} Targets:"; cat -n "$SCOPE_FILE"; } ;;
    *)         echo "Uso: scope [add|remove|list|clear] [target...]" ;;
esac
SCOPEEOF

    # xpaste: pegado inteligente (detecta terminal vs GUI)
    cat > /usr/local/bin/xpaste << 'XPASTEEOF'
#!/usr/bin/env bash
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
CLASS=$(xdotool getactivewindow getwindowclassname 2>/dev/null | tr '[:upper:]' '[:lower:]')
case "$CLASS" in
    *kitty*|*xterm*|*alacritty*|*terminal*|*konsole*|*tilix*)
        xdotool key --clearmodifiers ctrl+shift+v ;;
    *)
        xdotool key --clearmodifiers ctrl+v ;;
esac
XPASTEEOF

    chmod +x /usr/local/bin/extract-ports /usr/local/bin/xcopy /usr/local/bin/scope /usr/local/bin/xpaste
    ok "Scripts CTF instalados"

    # ─── Scripts de resize bspwm ────────────────────────────────
    mkdir -p "$HOME_DIR/.config/bspwm/scripts"

    cat > "$HOME_DIR/.config/bspwm/scripts/bspwm_resize_expand.sh" << 'BSPWM_EXP'
#!/usr/bin/env bash
case "$1" in
    west)  bspc node -z left -20 0   || bspc node -z right -20 0 ;;
    east)  bspc node -z right 20 0   || bspc node -z left   20 0 ;;
    north) bspc node -z top 0 -20    || bspc node -z bottom 0 -20 ;;
    south) bspc node -z bottom 0 20  || bspc node -z top    0  20 ;;
esac
BSPWM_EXP

    cat > "$HOME_DIR/.config/bspwm/scripts/bspwm_resize_contract.sh" << 'BSPWM_CON'
#!/usr/bin/env bash
case "$1" in
    west)  bspc node -z left 20 0    || bspc node -z right  20 0 ;;
    east)  bspc node -z right -20 0  || bspc node -z left  -20 0 ;;
    north) bspc node -z top 0 20     || bspc node -z bottom  0 20 ;;
    south) bspc node -z bottom 0 -20 || bspc node -z top    0 -20 ;;
esac
BSPWM_CON

    chmod +x "$HOME_DIR/.config/bspwm/scripts/bspwm_resize_expand.sh" \
             "$HOME_DIR/.config/bspwm/scripts/bspwm_resize_contract.sh"
    ok "Scripts bspwm resize instalados"
}

# ---------------------------------------------------------------------------
# GENERACION DE DOTFILES
# ---------------------------------------------------------------------------
generate_dotfiles() {
    section "GENERANDO DOTFILES"

    mkdir -p "$CONFIG_DIR/bspwm"
    mkdir -p "$CONFIG_DIR/sxhkd"
    mkdir -p "$CONFIG_DIR/alacritty"
    mkdir -p "$CONFIG_DIR/picom"
    mkdir -p "$CONFIG_DIR/polybar"
    mkdir -p "$CONFIG_DIR/polybar/scripts"
    mkdir -p "$CONFIG_DIR/rofi/themes"
    mkdir -p "$CONFIG_DIR/dunst"
    mkdir -p "$WALLPAPERS_DIR"

    generate_bspwmrc
    generate_sxhkdrc
    generate_kitty
    generate_alacritty
    generate_picom
    generate_polybar
    generate_polybar_scripts
    generate_rofi
    generate_dunst
    generate_zshrc
    generate_p10k
    generate_aliases
    generate_wallpaper_script
    generate_welcome_message

    ok "Todos los dotfiles generados"
}

# ---------------------------------------------------------------------------
# BSPWMRC
# ---------------------------------------------------------------------------
generate_bspwmrc() {
    step "Generando bspwmrc..."
    cat > "$CONFIG_DIR/bspwm/bspwmrc" << 'BSPWMRC'
#!/usr/bin/env bash
# AutSecurity Box - bspwmrc

# --- Lanzar sxhkd (gestor de atajos) ---
pgrep -x sxhkd > /dev/null || sxhkd &

# --- Monitor y workspaces ---
MONITOR=$(bspc query -M --names | head -1)
bspc monitor "$MONITOR" -d 1 2 3 4 5 6 7 8 9 10

# --- Configuracion global ---
bspc config border_width          2
bspc config window_gap            8
bspc config split_ratio           0.52
bspc config borderless_monocle    true
bspc config gapless_monocle       true
bspc config focus_follows_pointer true
bspc config pointer_follows_focus false
bspc config single_monocle        false
bspc config click_to_focus        button1

# --- Colores AutSecurity (negro/rojo/blanco) ---
bspc config normal_border_color   "#1a1a2e"
bspc config active_border_color   "#00ff88"
bspc config focused_border_color  "#00ff88"
bspc config presel_feedback_color "#00cc66"

# --- Reglas de ventanas ---
bspc rule -a Alacritty             state=tiled
bspc rule -a firefox               desktop='^2' follow=on
bspc rule -a Burp-Suite            desktop='^3' follow=on state=tiled
bspc rule -a "Wireshark"           desktop='^4' follow=on
bspc rule -a "VirtualBox Manager"  desktop='^5'
bspc rule -a Galculator            state=floating
bspc rule -a feh                   state=floating
bspc rule -a Pavucontrol           state=floating
bspc rule -a "Nitrogen"            state=floating
bspc rule -a "Arandr"              state=floating
bspc rule -a Gpick                 state=floating rectangle=530x390+0+0
bspc rule -a Oblogout              state=fullscreen

# --- Autostart ---
# Fondo de pantalla
feh --bg-max --image-bg black ~/.local/share/wallpapers/autsecurity.jpg 2>/dev/null \
    || feh --bg-max --image-bg black ~/.local/share/wallpapers/autsecurity.png 2>/dev/null &

# Compositor (picom)
pgrep -x picom > /dev/null || picom --config ~/.config/picom/picom.conf &

# Barra de estado
~/.config/polybar/launch.sh &

# Notificaciones
pgrep -x dunst > /dev/null || dunst &

# Cursor en cruz
xsetroot -cursor_name left_ptr &

# Teclado layout
setxkbmap -layout us &

# Autorandr para multi-monitor
command -v autorandr &>/dev/null && autorandr --change &

# Clipboard VMware (integración host ↔ VM)
pgrep -x vmware-user >/dev/null || vmware-user &

BSPWMRC
    chmod +x "$CONFIG_DIR/bspwm/bspwmrc"
    ok "bspwmrc generado"
}

# ---------------------------------------------------------------------------
# SXHKDRC
# ---------------------------------------------------------------------------
generate_sxhkdrc() {
    step "Generando sxhkdrc..."
    cat > "$CONFIG_DIR/sxhkd/sxhkdrc" << 'SXHKDRC'
# =====================================================
# AutSecurity Box - sxhkdrc
# Atajos de teclado optimizados para pentesting CTF
# =====================================================

# =====================================================
# CLIPBOARD DUAL — seleccionar con mouse luego tecla
# =====================================================

# Slot 1: copiar seleccion / pegar
F1
    DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xclip -selection primary -o 2>/dev/null | DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xclip -selection clipboard
F2
    /usr/local/bin/xpaste

# Slot 2: copiar seleccion / pegar
F3
    DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xclip -selection primary -o 2>/dev/null | DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xsel --secondary --input
F4
    DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xsel --secondary --output 2>/dev/null | DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority xclip -selection clipboard && /usr/local/bin/xpaste

# --- Terminal principal (Kitty — reutiliza ventana existente) ---
super + Return
    kitty --single-instance

# --- Terminal flotante ---
super + shift + Return
    kitty --class AlacrittyFloat

# --- Launcher (Rofi) ---
super + d
    rofi -show drun -theme ~/.config/rofi/themes/autsecurity.rasi

# --- Rofi window switcher ---
super + shift + d
    rofi -show window -theme ~/.config/rofi/themes/autsecurity.rasi

# --- Rofi run ---
super + alt + d
    rofi -show run -theme ~/.config/rofi/themes/autsecurity.rasi

# --- Cerrar ventana ---
super + shift + q
    bspc node -c

# --- Matar ventana (fuerza) ---
super + ctrl + q
    bspc node -k

# --- Recargar sxhkd ---
super + Escape
    pkill -USR1 -x sxhkd

# --- Recargar bspwm ---
super + shift + r
    bspc wm -r

# --- Salir de bspwm ---
super + alt + q
    bspc quit

# =====================================================
# WORKSPACES
# =====================================================

# Cambiar workspace (super + numero)
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

# Mover ventana a workspace
super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'

# Workspace siguiente/anterior
super + bracket{left,right}
    bspc desktop -f {prev,next}.local

# Moverse al ultimo workspace
super + grave
    bspc desktop -f last

# =====================================================
# FOCO Y MOVIMIENTO DE VENTANAS
# =====================================================

# Foco con teclas vim
super + {h,j,k,l}
    bspc node -f {west,south,north,east}

# Mover ventana con teclas vim
super + shift + {h,j,k,l}
    bspc node -s {west,south,north,east}

# Cambiar split ratio
super + ctrl + {h,j,k,l}
    bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

# Foco con flechas
super + {Left,Down,Up,Right}
    bspc node -f {west,south,north,east}

# Navegar historial de foco
super + {o,i}
    bspc wm -h off; bspc node {older,newer} -f; bspc wm -h on

# =====================================================
# ESTADOS Y GESTION DE VENTANAS
# =====================================================

# Floating / tiled toggle
super + shift + space
    bspc node -t ~floating

# Fullscreen
super + f
    bspc node -t ~fullscreen

# Monocle
super + m
    bspc desktop -l next

# Pseudotile
super + p
    bspc node -t ~pseudo_tiled

# Swap con la ventana mas grande del workspace
super + g
    bspc node -s biggest.window

# Flags de nodo: marked / locked / sticky / private
super + ctrl + {m,x,y,z}
    bspc node -g {marked,locked,sticky,private}

# =====================================================
# REDIMENSIONADO DINAMICO
# =====================================================

# Expandir ventana
super + alt + {Left,Down,Up,Right}
    ~/.config/bspwm/scripts/bspwm_resize_expand.sh {west,south,north,east}

# Contraer ventana
super + alt + shift + {Left,Down,Up,Right}
    ~/.config/bspwm/scripts/bspwm_resize_contract.sh {west,south,north,east}

# =====================================================
# CAPTURAS DE PANTALLA
# =====================================================

# Pantalla completa
Print
    flameshot full -p ~/Screenshots/ && notify-send "Screenshot" "Pantalla completa guardada"

# Seleccion interactiva
super + Print
    flameshot gui

# Ventana activa al clipboard
super + shift + Print
    maim -i $(xdotool getactivewindow) | xclip -selection clipboard -t image/png && notify-send "Screenshot" "Ventana copiada al clipboard"

# =====================================================
# HERRAMIENTAS DE PENTESTING
# =====================================================

# Abrir Burp Suite
super + b
    burpsuite &

# Abrir Firefox en workspace 2
super + w
    bspc desktop -f '^2' && firefox &

# Abrir Wireshark
super + shift + w
    wireshark &

# Abrir gestor de archivos (Thunar)
super + e
    thunar &

# Info de red rapida
super + n
    kitty --class AlacrittyFloat bash -c "~/.config/polybar/scripts/net-info.sh; read -p 'Presiona ENTER para cerrar...'"

# Copiar IP local al clipboard
super + shift + F1
    ~/.config/polybar/scripts/copy-local-ip.sh

# Copiar IP VPN al clipboard
super + shift + F2
    ~/.config/polybar/scripts/copy-vpn-ip.sh

# Copiar IP del target al clipboard
super + shift + F3
    ~/.config/polybar/scripts/copy-target-ip.sh

# =====================================================
# VOLUMEN Y BRILLO
# =====================================================

XF86AudioRaiseVolume
    pactl set-sink-volume @DEFAULT_SINK@ +5%

XF86AudioLowerVolume
    pactl set-sink-volume @DEFAULT_SINK@ -5%

XF86AudioMute
    pactl set-sink-mute @DEFAULT_SINK@ toggle

XF86MonBrightnessUp
    brightnessctl set +5%

XF86MonBrightnessDown
    brightnessctl set 5%-

# =====================================================
# UTILIDADES
# =====================================================

# Bloquear pantalla (super+alt+l para no conflicto con vim-keys)
super + alt + l
    i3lock -c 0d0d0d || xscreensaver-command -lock

# Portapapeles con rofi
super + v
    rofi -show clipboard -theme ~/.config/rofi/themes/autsecurity.rasi

# Calculadora
super + c
    galculator &

SXHKDRC
    ok "sxhkdrc generado"
}

# ---------------------------------------------------------------------------
# KITTY
# ---------------------------------------------------------------------------
generate_kitty() {
    step "Generando configuracion de Kitty..."
    mkdir -p "$CONFIG_DIR/kitty"
    cat > "$CONFIG_DIR/kitty/kitty.conf" << 'KITTY'
# =====================================================
# AutSecurity Box - Kitty Terminal
# =====================================================

shell zsh
font_family      Hack Nerd Font
bold_font        Hack Nerd Font Bold
italic_font      Hack Nerd Font Italic
bold_italic_font Hack Nerd Font Bold Italic
font_size        11.0

window_padding_width 10 8
background_opacity   0.92
hide_window_decorations yes
remember_window_size  yes

cursor            #00ff88
cursor_shape      block
cursor_blink_interval 0.5
cursor_stop_blinking_after 0

scrollback_lines 10000
enable_audio_bell no

selection_background #00ff88
selection_foreground #0d0d1a

tab_bar_style              powerline
tab_powerline_style        slanted
tab_bar_background         #0d0d1a
tab_bar_min_tabs           1
tab_title_template         "{index}: {title}"
active_tab_background      #00ff88
active_tab_foreground      #0d0d1a
active_tab_font_style      bold
inactive_tab_background    #1a1a2e
inactive_tab_foreground    #888888
inactive_tab_font_style    normal

background  #0d0d1a
foreground  #e0e0e0

color0  #1a1a2e
color1  #e94560
color2  #4ade80
color3  #fbbf24
color4  #60a5fa
color5  #c084fc
color6  #22d3ee
color7  #e2e8f0
color8  #374151
color9  #ff6b6b
color10 #86efac
color11 #fde047
color12 #93c5fd
color13 #d8b4fe
color14 #67e8f9
color15 #f8fafc

# Tabs
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+alt+t set_tab_title
map ctrl+shift+right next_tab
map ctrl+shift+left  previous_tab
map ctrl+shift+1 goto_tab 1
map ctrl+shift+2 goto_tab 2
map ctrl+shift+3 goto_tab 3
map ctrl+shift+4 goto_tab 4
map ctrl+shift+5 goto_tab 5
map ctrl+shift+6 goto_tab 6
map ctrl+shift+7 goto_tab 7
map ctrl+shift+8 goto_tab 8
map ctrl+shift+9 goto_tab 9
map ctrl+shift+0 goto_tab 10
map ctrl+shift+w close_tab

# Copiar / Pegar — ctrl+v tambien funciona (necesario para F2/F4 clipboard)
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+v       paste_from_clipboard

# Fuente
map ctrl+shift+equal    change_font_size all +1.0
map ctrl+shift+minus    change_font_size all -1.0
map ctrl+shift+backspace change_font_size all 0

# Ventanas dentro de tab
map ctrl+shift+enter new_window
map ctrl+shift+q     close_window
KITTY
    ok "kitty.conf generado"
}

# ---------------------------------------------------------------------------
# ALACRITTY
# ---------------------------------------------------------------------------
generate_alacritty() {
    step "Generando configuracion de Alacritty..."
    cat > "$CONFIG_DIR/alacritty/alacritty.toml" << 'ALACRITTY'
# =====================================================
# AutSecurity Box - Alacritty Configuration
# Tema: Dark Hacking / AutSecurity
# =====================================================

[env]
TERM = "xterm-256color"

[window]
padding = { x = 10, y = 8 }
decorations = "none"
opacity = 0.92
blur = true
startup_mode = "Windowed"
title = "AutSecurity Terminal"
dynamic_title = true

[window.dimensions]
columns = 120
lines = 35

[scrolling]
history = 10000
multiplier = 3

[font]
size = 11.0

[font.normal]
family = "Hack Nerd Font"
style = "Regular"

[font.bold]
family = "Hack Nerd Font"
style = "Bold"

[font.italic]
family = "Hack Nerd Font"
style = "Italic"

[font.bold_italic]
family = "Hack Nerd Font"
style = "Bold Italic"

# --- Tema AutSecurity Dark ---
[colors.primary]
background = "#0d0d1a"
foreground = "#e0e0e0"
bright_foreground = "#ffffff"

[colors.cursor]
text   = "#0d0d1a"
cursor = "#e94560"

[colors.vi_mode_cursor]
text   = "#0d0d1a"
cursor = "#ff6b35"

[colors.search.matches]
foreground = "#0d0d1a"
background = "#e94560"

[colors.search.focused_match]
foreground = "#0d0d1a"
background = "#ff6b35"

[colors.normal]
black   = "#1a1a2e"
red     = "#e94560"
green   = "#4ade80"
yellow  = "#fbbf24"
blue    = "#60a5fa"
magenta = "#c084fc"
cyan    = "#22d3ee"
white   = "#e2e8f0"

[colors.bright]
black   = "#374151"
red     = "#ff6b6b"
green   = "#86efac"
yellow  = "#fde047"
blue    = "#93c5fd"
magenta = "#d8b4fe"
cyan    = "#67e8f9"
white   = "#f8fafc"

[colors.dim]
black   = "#0f0f1a"
red     = "#c0392b"
green   = "#27ae60"
yellow  = "#e67e22"
blue    = "#2980b9"
magenta = "#8e44ad"
cyan    = "#16a085"
white   = "#bdc3c7"

[cursor]
style = { shape = "Block", blinking = "On" }
blink_interval = 500
unfocused_hollow = true

[selection]
save_to_clipboard = true

[keyboard]
bindings = [
    { key = "V",        mods = "Control|Shift", action = "Paste" },
    { key = "C",        mods = "Control|Shift", action = "Copy" },
    { key = "Plus",     mods = "Control",       action = "IncreaseFontSize" },
    { key = "Minus",    mods = "Control",       action = "DecreaseFontSize" },
    { key = "Key0",     mods = "Control",       action = "ResetFontSize" },
    { key = "F11",                              action = "ToggleFullscreen" },
    { key = "Return",   mods = "Control|Shift", action = "SpawnNewInstance" },
]

[mouse]
hide_when_typing = true

ALACRITTY
    ok "alacritty.toml generado"
}

# ---------------------------------------------------------------------------
# PICOM
# ---------------------------------------------------------------------------
generate_picom() {
    step "Generando picom.conf..."
    cat > "$CONFIG_DIR/picom/picom.conf" << 'PICOM'
# =====================================================
# AutSecurity Box - Picom Compositor
# =====================================================

# --- Backend ---
# xrender: mas estable con bspwm, sin bugs de renderizado en terminales
backend = "xrender";

# --- Sincronizacion (fix tearing en VM) ---
# El driver vmwgfx (VMware) y los drivers KMS simulan el vblank por software.
# Sin estas dos opciones aparecen "cuadros" con imagen vieja (ghosting) y
# tearing al cambiar ventanas o abrir el navegador.
#
# xrender-sync-fence: usa X Sync fences para garantizar que el renderizado
# termina antes del swap de buffer. Necesario cuando el vblank no es hardware.
xrender-sync-fence = true;
#
# use-damage = false: fuerza redibujado completo del frame en lugar de solo
# las regiones "danadas". El driver vmwgfx no reporta damage correctamente,
# causando que picom omita redibujar zonas que si cambiaron. Costo minimo
# en VM porque el driver hace su propio damage tracking a nivel kernel.
use-damage = false;

# --- Sombras ---
shadow = true;
shadow-radius = 15;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.6;
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "class_g = 'Cairo-clock'",
    "_GTK_FRAME_EXTENTS@",
    "class_g = 'slop'",
    "class_g = 'Polybar'"
];

# --- Transparencias ---
inactive-opacity = 0.88;
active-opacity = 0.95;
frame-opacity = 0.85;
inactive-opacity-override = false;

opacity-rule = [
    "100:class_g = 'firefox'",
    "100:class_g = 'Burp-Suite'",
    "100:class_g = 'Wireshark'",
    "100:class_g = 'VirtualBox Machine'",
    "98:class_g  = 'Alacritty'",
    "90:class_g  = 'Rofi'"
];

# --- Blur (solo funciona con backend glx) ---
# blur-method = "dual_kawase";
# blur-strength = 5;
# blur-background = true;

# --- Fade ---
fading = true;
fade-in-step  = 0.04;
fade-out-step = 0.04;
fade-delta = 4;
# Evita el glitch de ventana en blanco al abrir/cerrar
no-fading-openclose = true;

# --- General ---
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
use-ewmh-active-win = true;
detect-transient = true;
detect-client-leader = true;
vsync = true;
unredir-if-possible = false;

# --- Esquinas redondeadas ---
corner-radius = 8;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

PICOM
    ok "picom.conf generado"
}

# ---------------------------------------------------------------------------
# POLYBAR
# ---------------------------------------------------------------------------
generate_polybar() {
    step "Generando configuracion de Polybar..."

    # Script de lanzamiento
    cat > "$CONFIG_DIR/polybar/launch.sh" << 'LAUNCH'
#!/usr/bin/env bash
# Matar instancias previas
killall -q polybar

# Esperar a que terminen
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.5; done

# Detectar monitores y lanzar
if type "xrandr" > /dev/null; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
        disown
    done
else
    polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
    disown
fi
LAUNCH
    chmod +x "$CONFIG_DIR/polybar/launch.sh"

    # Configuracion principal
    cat > "$CONFIG_DIR/polybar/config.ini" << 'POLYBAR'
; =====================================================
; AutSecurity Box - Polybar Configuration
; =====================================================

[colors]
bg         = #cc0d0d1a
bg-alt     = #1a1a2e
fg         = #e0e0e0
fg-alt     = #888888
red        = #e94560
orange     = #ff6b35
green      = #4ade80
yellow     = #fbbf24
blue       = #60a5fa
cyan       = #22d3ee
magenta    = #c084fc
white      = #f8fafc
black      = #0d0d1a
separator  = #374151

; =====================================================
[bar/main]
; --- Geometria ---
width   = 100%
height  = 28pt
offset-x = 0
offset-y = 0
radius  = 0

; --- Posicion ---
bottom  = false
fixed-center = true

; --- Colores ---
background = ${colors.bg}
foreground = ${colors.fg}

; --- Borde ---
border-bottom-size = 2
border-bottom-color = #00ff88

; --- Fuente ---
font-0 = "Hack Nerd Font:size=9:antialias=true;3"
font-1 = "Hack Nerd Font:size=12:antialias=true;3"
font-2 = "Hack Nerd Font Mono:size=10:antialias=true;3"

; --- Modulos ---
modules-left   = bspwm scope-status
modules-center = date
modules-right  = vpn localip cpu memory fs-root volume

; --- Cursor ---
cursor-click  = pointer
cursor-scroll = ns-resize

; --- Padding ---
padding-left  = 0
padding-right = 1
module-margin = 1

; --- Tray ---
tray-position = right
tray-padding  = 4
tray-background = ${colors.bg-alt}

; --- Misc ---
enable-ipc = true
wm-restack = bspwm

; =====================================================
; MODULOS
; =====================================================

[module/bspwm]
type = internal/bspwm
pin-workspaces = true
inline-mode = false
enable-click = true
enable-scroll = true
reverse-scroll = true
fuzzy-match = true

format = <label-state> <label-mode>

label-focused         = %name%
label-focused-foreground = #0d0d1a
label-focused-background = #00ff88
label-focused-padding = 2

label-occupied         = %name%
label-occupied-foreground = ${colors.fg}
label-occupied-padding = 2

label-urgent           = %name%
label-urgent-foreground = ${colors.bg}
label-urgent-background = ${colors.orange}
label-urgent-padding   = 2

label-empty            = %name%
label-empty-foreground = ${colors.fg-alt}
label-empty-padding    = 2

label-monocle          =
label-tiled            =
label-floating         =

[module/xwindow]
type = internal/xwindow
label = %title:0:50:...%
label-foreground = ${colors.fg-alt}
format-prefix = "  "
format-prefix-foreground = ${colors.cyan}

; =====================================================
[module/vpn]
type = custom/script
exec = ~/.config/polybar/scripts/vpn.sh
interval = 3
label = %output%
format-prefix = "  "
format-prefix-foreground = ${colors.orange}

[module/localip]
type = custom/script
exec = ~/.config/polybar/scripts/localip.sh
interval = 5
label = %output%
format-prefix = "󰩟  "
format-prefix-foreground = ${colors.blue}

; =====================================================
[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "󰻠  "
format-prefix-foreground = ${colors.red}
label = %percentage:2%%
label-foreground = ${colors.fg}

[module/memory]
type = internal/memory
interval = 2
format-prefix = "󰍛  "
format-prefix-foreground = ${colors.magenta}
label = %percentage_used:2%%

[module/fs-root]
type = internal/fs
mount-0 = /
interval = 30
format-mounted-prefix = "󰋊  "
format-mounted-prefix-foreground = ${colors.yellow}
label-mounted = %percentage_used%%

; =====================================================
[module/date]
type = internal/date
interval = 1
date         = "%a %d %b"
time         = "%H:%M:%S"
date-alt     = "%Y-%m-%d"
time-alt     = "%H:%M:%S"
label = %date%  %time%
label-foreground = ${colors.fg}
format-prefix = "  "
format-prefix-foreground = ${colors.cyan}

; =====================================================
[module/volume]
type = internal/pulseaudio
format-volume-prefix = "󰕾  "
format-volume-prefix-foreground = ${colors.green}
label-volume = %percentage%%
format-muted-prefix = "󰖁  "
format-muted-prefix-foreground = ${colors.fg-alt}
label-muted = muted
label-muted-foreground = ${colors.fg-alt}

; =====================================================
[module/scope-status]
type = custom/script
exec = ~/.config/polybar/scripts/scope-status.sh
interval = 3
label = %output%

POLYBAR
    ok "polybar/config.ini generado"
}

# ---------------------------------------------------------------------------
# POLYBAR SCRIPTS
# ---------------------------------------------------------------------------
generate_polybar_scripts() {
    step "Generando scripts de Polybar..."

    # VPN / tun0
    cat > "$CONFIG_DIR/polybar/scripts/vpn.sh" << 'VPN'
#!/usr/bin/env bash
VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [[ -n "$VPN_IP" ]]; then
    echo "%{F#e94560}VPN:%{F-} $VPN_IP"
else
    echo "%{F#888888}VPN: desconectada%{F-}"
fi
VPN

    # IP local
    cat > "$CONFIG_DIR/polybar/scripts/localip.sh" << 'LOCALIP'
#!/usr/bin/env bash
LOCAL_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [[ -n "$LOCAL_IP" ]]; then
    IFACE=$(ip -4 addr show scope global | grep -B1 "inet $LOCAL_IP" | grep -oP '^\d+: \K[^:]+')
    echo "${IFACE:-eth0}: $LOCAL_IP"
else
    echo "sin red"
fi
LOCALIP

    # Scope status
    cat > "$CONFIG_DIR/polybar/scripts/scope-status.sh" << 'SCOPEST'
#!/usr/bin/env bash
SCOPE_FILE="$HOME/.config/bin/scope"
if [[ ! -f "$SCOPE_FILE" || ! -s "$SCOPE_FILE" ]]; then
    echo "%{F#888888}Sin scope%{F-}"
else
    echo "%{F#00ff88}Scope ($(wc -l < "$SCOPE_FILE"))%{F-}"
fi
SCOPEST

    # Info de red completa (para el atajo super+n)
    cat > "$CONFIG_DIR/polybar/scripts/net-info.sh" << 'NETINFO'
#!/usr/bin/env bash
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════╗${NC}"
echo -e "${RED}║   AutSecurity Box - Network Info   ║${NC}"
echo -e "${RED}╚════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Interfaces activas:${NC}"
ip -4 addr show scope global | awk '/^[0-9]+:/{iface=$2} /inet/{print "  " iface " -> " $2}'
echo ""

VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [[ -n "$VPN_IP" ]]; then
    echo -e "${GREEN}VPN (tun0): $VPN_IP${NC}"
else
    echo -e "${ORANGE}VPN: No conectada${NC}"
fi

echo ""
echo -e "${CYAN}Gateway:${NC} $(ip route | grep default | awk '{print $3}' | head -1)"
echo -e "${CYAN}DNS:${NC}     $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -3 | tr '\n' ' ')"
NETINFO

    chmod +x "$CONFIG_DIR/polybar/scripts/"*.sh
    ok "Scripts de Polybar generados"
}

# ---------------------------------------------------------------------------
# ROFI
# ---------------------------------------------------------------------------
generate_rofi() {
    step "Generando tema Rofi..."
    cat > "$CONFIG_DIR/rofi/themes/autsecurity.rasi" << 'ROFI'
/* =====================================================
   AutSecurity Box - Rofi Theme
   ===================================================== */

* {
    bg0:     #0d0d1aee;
    bg1:     #1a1a2eee;
    bg2:     #16213099;
    fg0:     #e0e0e0;
    fg1:     #888888;
    red:     #e94560;
    orange:  #ff6b35;
    green:   #4ade80;
    cyan:    #22d3ee;
    font:    "Hack Nerd Font 11";
    border:  0px;
    margin:  0px;
    padding: 0px;
    spacing: 0px;
}

window {
    width:            600px;
    background-color: @bg0;
    border:           2px solid;
    border-color:     @red;
    border-radius:    8px;
    padding:          12px;
}

mainbox {
    background-color: transparent;
    children:         [ inputbar, message, listview ];
    spacing:          8px;
}

inputbar {
    background-color: @bg1;
    border-radius:    6px;
    padding:          8px 12px;
    children:         [ prompt, entry ];
    spacing:          6px;
}

prompt {
    background-color: transparent;
    text-color:       @red;
    font:             "Hack Nerd Font Bold 11";
}

entry {
    background-color: transparent;
    text-color:       @fg0;
    placeholder:      "Buscar...";
    placeholder-color: @fg1;
}

listview {
    background-color: transparent;
    lines:            10;
    columns:          1;
    spacing:          2px;
    scrollbar:        false;
}

element {
    background-color: transparent;
    padding:          6px 10px;
    border-radius:    4px;
    children:         [ element-icon, element-text ];
    spacing:          8px;
}

element selected {
    background-color: @red;
}

element-icon {
    size:             20px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color:       @fg0;
    vertical-align:   0.5;
}

element selected element-text {
    text-color: #ffffff;
}

message {
    background-color: @bg2;
    border-radius:    4px;
    padding:          6px;
}

ROFI
    ok "Tema Rofi generado"
}

# ---------------------------------------------------------------------------
# DUNST
# ---------------------------------------------------------------------------
generate_dunst() {
    step "Generando dunstrc..."
    cat > "$CONFIG_DIR/dunst/dunstrc" << 'DUNST'
[global]
    monitor = 0
    follow = mouse
    width = 380
    height = 200
    origin = top-right
    offset = 12x50
    scale = 0
    notification_limit = 5
    progress_bar = true
    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 10
    horizontal_padding = 12
    text_icon_padding = 10
    frame_width = 2
    frame_color = "#e94560"
    separator_color = "#374151"
    sort = yes
    font = Hack Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    enable_recursive_icon_lookup = true
    icon_position = left
    min_icon_size = 32
    max_icon_size = 48
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/rofi -p dunst:
    browser = /usr/bin/firefox
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 8
    ignore_dbusclose = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#0d0d1a"
    foreground = "#e0e0e0"
    frame_color = "#374151"
    timeout = 4

[urgency_normal]
    background = "#0d0d1a"
    foreground = "#e0e0e0"
    frame_color = "#e94560"
    timeout = 6

[urgency_critical]
    background = "#1a0000"
    foreground = "#ffffff"
    frame_color = "#ff0000"
    timeout = 0

DUNST
    ok "dunstrc generado"
}

# ---------------------------------------------------------------------------
# ZSHRC
# ---------------------------------------------------------------------------
generate_zshrc() {
    step "Generando .zshrc..."
    cat > "$HOME_DIR/.zshrc" << 'ZSHRC'
# =====================================================
# AutSecurity Box - .zshrc
# =====================================================

# --- Powerlevel10k instant prompt ---
# DEBE ser lo primero. No poner nada que genere output antes de este bloque.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Path a Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"

# --- Tema ---
ZSH_THEME="powerlevel10k/powerlevel10k"

# --- Plugins ---
plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    fzf-tab
    colored-man-pages
    command-not-found
    extract
    z
    docker
    python
    pip
)

# --- Pre oh-my-zsh custom config ---
[[ -f ~/.zshrc.pre-oh-my-zsh ]] && source ~/.zshrc.pre-oh-my-zsh

source $ZSH/oh-my-zsh.sh

# --- Autocompletado (zsh-autocomplete - cargar aparte) ---
# source ~/.oh-my-zsh/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# --- FZF ---
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='
    --color=fg:#e0e0e0,fg+:#ffffff,bg:#0d0d1a,bg+:#1a1a2e
    --color=hl:#e94560,hl+:#ff6b35,info:#fbbf24,marker:#4ade80
    --color=prompt:#e94560,spinner:#22d3ee,pointer:#ff6b35,header:#60a5fa
    --border=rounded --height=50% --layout=reverse --info=inline
'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null || find . -type d'

# --- PATH ---
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$HOME/.cargo/bin:$PATH"
export GOPATH="$HOME/go"

# --- Configuracion de historial ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY

# --- Opciones de shell ---
setopt AUTO_CD
setopt CORRECT
setopt GLOB_DOTS
setopt NO_BEEP
setopt EXTENDED_GLOB

# --- Autosuggestions config ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#555555"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# --- Syntax highlighting config ---
ZSH_HIGHLIGHT_STYLES[alias]='fg=#4ade80,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#60a5fa,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#c084fc,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=#4ade80'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e94560'
ZSH_HIGHLIGHT_STYLES[path]='fg=#22d3ee,underline'

# --- Cargar aliases ---
[[ -f ~/.aliases ]] && source ~/.aliases

# --- Herramientas de pentesting en PATH ---
export PATH="$PATH:/opt/metasploit-framework/bin"

# --- Completados adicionales ---
autoload -Uz compinit && compinit -d ~/.zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'

# --- Powerlevel10k config ---
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- Mensaje de bienvenida ---
# Se carga al final para no interferir con instant prompt
if [[ $- == *i* ]] && [[ -z "$INSIDE_WELCOME" ]]; then
    export INSIDE_WELCOME=1
    source ~/.config/autsecurity/welcome.sh 2>/dev/null
fi

ZSHRC

    # Archivo pre-oh-my-zsh: se carga antes de omz, util para aliases de sistema
    cat > "$HOME_DIR/.zshrc.pre-oh-my-zsh" << 'PREZSHRC'
# AutSecurity Box - pre-oh-my-zsh
# Cargado antes de Oh My Zsh — para aliases que deben definirse primero
alias cat='/usr/bin/batcat'
PREZSHRC
    ok ".zshrc y .zshrc.pre-oh-my-zsh generados"
}

# ---------------------------------------------------------------------------
# POWERLEVEL10K CONFIG
# ---------------------------------------------------------------------------
generate_p10k() {
    step "Generando .p10k.zsh (Powerlevel10k)..."
    cat > "$HOME_DIR/.p10k.zsh" << 'P10K'
# =====================================================
# AutSecurity Box - Powerlevel10k Config
# =====================================================

# Desactivar instant prompt aqui (se inicializa en .zshrc antes de omz)
# Este valor 'quiet' suprime warnings de output durante init
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# --- Elementos del prompt ---
# Linea izquierda: icono OS + directorio + git + cursor (todo en una sola linea)
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  dir
  vcs
  prompt_char
)

# Linea derecha: solo estado y jobs en background
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  background_jobs
)

# --- Modo de iconos ---
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_ICON_PADDING=moderate

# --- Icono de OS ---
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=196
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=233

# --- Directorio ---
typeset -g POWERLEVEL9K_DIR_BACKGROUND=233
typeset -g POWERLEVEL9K_DIR_FOREGROUND=196
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=167
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=196
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

# --- Git ---
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=' '
typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=28
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=130
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=88

# --- Caracter del prompt ---
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=76
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''

# --- Estado del ultimo comando ---
typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=233

# --- Tiempo de ejecucion ---
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=130
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=233

# --- Separacion entre prompts ---
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# --- Separadores (powerline style) ---
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0B0'
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='\uE0B1'
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR='\uE0B3'

# --- Jobs en background ---
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=70
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=233

# --- Linea en blanco antes de cada prompt ---
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# --- Prompt transitorio (limpia prompts anteriores) ---
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
P10K
    ok ".p10k.zsh generado"
}

# ---------------------------------------------------------------------------
# ALIASES
# ---------------------------------------------------------------------------
generate_aliases() {
    step "Generando .aliases..."
    cat > "$HOME_DIR/.aliases" << 'ALIASES'
# =====================================================
# AutSecurity Box - Aliases y Funciones de Pentesting
# =====================================================

# --- Navegacion ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'
alias ll='ls -lah --color=auto'
alias la='ls -la --color=auto'
alias l='ls -lh --color=auto'
alias lt='ls -lahtr --color=auto'
alias tree='tree -C'

# Usar bat si esta disponible
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'
fi

# Usar fd si esta disponible
if command -v fdfind &>/dev/null; then
    alias fd='fdfind'
fi

# Usar ripgrep
alias rg='rg --color=always'

# --- Sistema ---
alias cls='clear'
alias h='history'
alias j='jobs -l'
alias reload='source ~/.zshrc'
alias aliases='vim ~/.aliases'
alias zshrc='vim ~/.zshrc'
alias hosts='sudo vim /etc/hosts'
alias myip='curl -s ifconfig.me && echo'
alias ports='ss -tulnp'
alias psg='ps aux | grep -v grep | grep'

# --- Red / Pentesting base ---
alias lip='ip -4 addr show scope global | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -1'
alias vpnip='ip -4 addr show tun0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias vpn='sudo openvpn'
alias netinfo='~/.config/polybar/scripts/net-info.sh'

# --- Nmap ---
alias nmap-quick='nmap -sV -sC -T4 --open'
alias nmap-full='nmap -sV -sC -p- -T4 --open'
alias nmap-udp='nmap -sU -T4 --open --top-ports 200'
alias nmap-vuln='nmap -sV --script=vuln'
alias nmap-stealth='nmap -sS -T2 --open'
nmap-all() {
    echo "[*] Scan rapido inicial..."
    nmap -T4 --open -p- "$1" -oN /tmp/nmap_ports.txt 2>/dev/null
    PORTS=$(grep "^[0-9]" /tmp/nmap_ports.txt | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    echo "[*] Ports: $PORTS"
    echo "[*] Scan detallado en puertos abiertos..."
    nmap -sV -sC -p "$PORTS" "$1" -oN /tmp/nmap_full.txt
    echo "[+] Resultados en /tmp/nmap_full.txt"
}

# --- Web ---
alias gobuster-dir='gobuster dir -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -t 50'
alias gobuster-vhost='gobuster vhost -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt'
alias ffuf-dir='ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -u'
alias ffuf-vhost='ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -H "Host: FUZZ.TARGET" -u'
alias ferox='feroxbuster --wordlist /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt'
alias nikto='nikto -host'

# --- SMB ---
alias smb-list='smbclient -L'
alias smb-null='smbclient -L -N'
alias enum4='enum4linux-ng'
alias crackmape='crackmapexec smb'

# --- AD / Kerberos ---
alias bloodhound-start='sudo neo4j start && sleep 5 && bloodhound &'
alias neo4j-start='sudo neo4j start'
alias kerbrute-users='kerbrute userenum -d'
alias getspn='GetUserSPNs.py'
alias getnpusers='GetNPUsers.py'

# --- Hashcat ---
alias hc='hashcat'
alias hc-ntlm='hashcat -m 1000'
alias hc-sha1='hashcat -m 100'
alias hc-md5='hashcat -m 0'
alias hc-krb5='hashcat -m 13100'
alias hc-rockyou='hashcat --wordlist /usr/share/wordlists/rockyou.txt'

# --- John ---
alias john-rockyou='john --wordlist=/usr/share/wordlists/rockyou.txt'
alias john-show='john --show'

# --- Tunneling ---
alias chisel-server='chisel server --reverse --port 9001'
alias chisel-client='chisel client'
alias ligolo='sudo ligolo-proxy -selfcert'

# --- Metasploit ---
alias msf='msfconsole'
alias msfdb-init='sudo msfdb init'

# --- Burp ---
alias burp='burpsuite &>/dev/null &'

# --- Utilidades ---
alias extract='_extract'
_extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"   ;;
            *.tar.gz)  tar xzf "$1"   ;;
            *.tar.xz)  tar xJf "$1"   ;;
            *.bz2)     bunzip2 "$1"   ;;
            *.rar)     unrar x "$1"   ;;
            *.gz)      gunzip "$1"    ;;
            *.tar)     tar xf "$1"    ;;
            *.tbz2)    tar xjf "$1"   ;;
            *.tgz)     tar xzf "$1"   ;;
            *.zip)     unzip "$1"     ;;
            *.Z)       uncompress "$1";;
            *.7z)      7z x "$1"      ;;
            *)         echo "'$1' no se puede extraer automáticamente" ;;
        esac
    else
        echo "'$1' no es un archivo valido"
    fi
}

# --- Transferencia de archivos ---
alias serve='python3 -m http.server 8080'
alias serve-php='php -S 0.0.0.0:8080'
transfer() {
    curl --upload-file "$1" "https://transfer.sh/$(basename $1)"
}

# --- Git ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# --- Creacion de entorno de trabajo CTF ---
ctf-init() {
    local nombre="${1:-machine}"
    local dir="$HOME/ctf/$nombre"
    mkdir -p "$dir"/{recon,exploit,post,files,notes}
    cat > "$dir/notes/README.md" << EOF
# CTF: $nombre
Fecha: $(date +%Y-%m-%d)

## IP objetivo
TARGET=

## Fases
### Reconocimiento
### Enumeracion
### Explotacion
### Post-Explotacion
### Flags
user.txt:
root.txt:
EOF
    echo "[+] Entorno CTF creado en $dir"
    cd "$dir"
}

# --- Target helper ---
target() {
    if [[ -z "$1" ]]; then
        echo "[*] TARGET actual: $TARGET"
    else
        export TARGET="$1"
        echo "[+] TARGET configurado: $TARGET"
        grep -q "$TARGET" /etc/hosts 2>/dev/null || echo "[!] Tip: agrega $TARGET a /etc/hosts si es necesario"
    fi
}

# --- Wrapper nmap rapido ---
recon() {
    [[ -z "$1" ]] && echo "Uso: recon <IP>" && return 1
    local ip="${1:-$TARGET}"
    local outdir="${2:-.}"
    echo "[*] Reconocimiento de $ip..."
    nmap -sV -sC -T4 --open "$ip" -oN "$outdir/nmap_${ip}.txt" 2>&1
    echo "[+] Guardado en $outdir/nmap_${ip}.txt"
}

ALIASES
    ok ".aliases generado"
}

# ---------------------------------------------------------------------------
# WALLPAPER Y SPLASH SCREEN
# ---------------------------------------------------------------------------
generate_wallpaper_script() {
    step "Configurando wallpaper AutSecurity..."
    mkdir -p "$WALLPAPERS_DIR"

    # Buscar imagen personalizada junto al script (prioridad: jpg > png > logo_updated.png)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for img in "autsecurity.jpg" "autsecurity.png" "logo_updated.png"; do
        if [[ -f "$script_dir/$img" ]]; then
            local ext="${img##*.}"
            cp "$script_dir/$img" "$WALLPAPERS_DIR/autsecurity.${ext}"
            ok "Wallpaper copiado desde $script_dir/$img"
            return 0
        fi
    done

    # Si no hay imagen propia, genera un wallpaper minimalista SVG
    cat > "/tmp/autsecurity_wallpaper.svg" << 'SVGWALL'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
  <defs>
    <radialGradient id="bg" cx="50%" cy="50%" r="70%">
      <stop offset="0%"   stop-color="#0d1117"/>
      <stop offset="60%"  stop-color="#0d0d1a"/>
      <stop offset="100%" stop-color="#050508"/>
    </radialGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="4" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Fondo -->
  <rect width="1920" height="1080" fill="url(#bg)"/>

  <!-- Grid de puntos decorativos -->
  <g opacity="0.04" fill="#e94560">
    <script type="text/plain">
    </script>
  </g>

  <!-- Lineas de circuito decorativas -->
  <g stroke="#e94560" stroke-width="1" opacity="0.08" fill="none">
    <path d="M0,400 H300 V200 H600"/>
    <path d="M1920,600 H1600 V800 H1300"/>
    <path d="M0,700 H200 V900 H500 V1080"/>
    <path d="M1920,300 H1700 V100 H1400"/>
    <circle cx="300" cy="200" r="4" fill="#e94560" opacity="0.3"/>
    <circle cx="600" cy="200" r="4" fill="#e94560" opacity="0.3"/>
    <circle cx="1600" cy="800" r="4" fill="#e94560" opacity="0.3"/>
    <circle cx="1300" cy="800" r="4" fill="#e94560" opacity="0.3"/>
  </g>

  <!-- Hexagonos de fondo -->
  <g opacity="0.05" stroke="#ff6b35" stroke-width="1" fill="none">
    <polygon points="960,200 1005,225 1005,275 960,300 915,275 915,225"/>
    <polygon points="860,380 905,405 905,455 860,480 815,455 815,405"/>
    <polygon points="1060,380 1105,405 1105,455 1060,480 1015,455 1015,405"/>
    <polygon points="960,560 1005,585 1005,635 960,660 915,635 915,585"/>
  </g>

  <!-- Texto principal: AutSecurity -->
  <text x="960" y="490" font-family="monospace" font-size="82" font-weight="bold"
        text-anchor="middle" fill="#e94560" filter="url(#glow)" opacity="0.95"
        letter-spacing="8">AutSecurity</text>

  <!-- Subtitulo: Box -->
  <text x="960" y="570" font-family="monospace" font-size="48" font-weight="bold"
        text-anchor="middle" fill="#ff6b35" opacity="0.85" letter-spacing="20">B O X</text>

  <!-- Linea separadora -->
  <line x1="660" y1="595" x2="1260" y2="595" stroke="#e94560" stroke-width="1.5" opacity="0.4"/>

  <!-- Tagline -->
  <text x="960" y="630" font-family="monospace" font-size="16"
        text-anchor="middle" fill="#888888" letter-spacing="4">
    CTF  |  Pentesting  |  Red Team
  </text>

  <!-- Esquinas decorativas -->
  <g stroke="#e94560" stroke-width="2" fill="none" opacity="0.3">
    <path d="M40,40 H120 M40,40 V120"/>
    <path d="M1880,40 H1800 M1880,40 V120"/>
    <path d="M40,1040 H120 M40,1040 V960"/>
    <path d="M1880,1040 H1800 M1880,1040 V960"/>
  </g>

  <!-- Version / branding bottom -->
  <text x="960" y="1055" font-family="monospace" font-size="12"
        text-anchor="middle" fill="#333344" letter-spacing="2">
    AutSecurity Box  //  Kali Linux  //  bspwm
  </text>
</svg>
SVGWALL

    mkdir -p "$WALLPAPERS_DIR"
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 /tmp/autsecurity_wallpaper.svg "$WALLPAPERS_DIR/autsecurity.jpg" 2>/dev/null \
            && ok "Wallpaper minimalista generado con ImageMagick"
    elif command -v rsvg-convert &>/dev/null; then
        rsvg-convert -w 1920 -h 1080 /tmp/autsecurity_wallpaper.svg > "$WALLPAPERS_DIR/autsecurity.jpg" 2>/dev/null \
            && ok "Wallpaper minimalista generado con rsvg-convert"
    else
        warn "No se encontro convertidor SVG, usando SVG directamente"
        cp /tmp/autsecurity_wallpaper.svg "$WALLPAPERS_DIR/autsecurity.svg"
    fi
}

# ---------------------------------------------------------------------------
# WELCOME MESSAGE
# ---------------------------------------------------------------------------
generate_welcome_message() {
    step "Generando mensaje de bienvenida..."
    mkdir -p "$HOME_DIR/.config/autsecurity"

    cat > "$HOME_DIR/.config/autsecurity/welcome.sh" << 'WELCOME'
#!/usr/bin/env bash
# AutSecurity Box - Welcome Message

RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

# Solo mostrar una vez por sesion
[[ -n "$AUTSEC_WELCOME_SHOWN" ]] && return
export AUTSEC_WELCOME_SHOWN=1

echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║${NC}                                      ${GREEN}║${NC}"
echo -e "  ${GREEN}║${NC}         ${WHITE}A u t S e c B o x${NC}            ${GREEN}║${NC}"
echo -e "  ${GREEN}║${NC}                                      ${GREEN}║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

# Info del sistema
LOCAL_IP=$(ip -4 addr show scope global 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')

echo -e "  ${DIM}Fecha:${NC}   $(date '+%A, %d %B %Y  %H:%M:%S')"
echo -e "  ${DIM}Kernel:${NC}  ${KERNEL}"
echo -e "  ${DIM}Uptime:${NC}  ${UPTIME}"
echo ""
echo -e "  ${CYAN}IP Local:${NC}  ${WHITE}${LOCAL_IP:-sin red}${NC}"
if [[ -n "$VPN_IP" ]]; then
    echo -e "  ${GREEN}VPN (tun0):${NC} ${WHITE}$VPN_IP${NC}  ${GREEN}[CONECTADA]${NC}"
else
    echo -e "  ${ORANGE}VPN (tun0):${NC} ${DIM}desconectada${NC}"
fi
echo ""
echo -e "  ${DIM}${RED}ctf-init <nombre>${NC}${DIM}  -  Crea entorno de trabajo para maquina${NC}"
echo -e "  ${DIM}${RED}target <IP>${NC}${DIM}        -  Define IP objetivo y exporta \$TARGET${NC}"
echo -e "  ${DIM}${RED}recon <IP>${NC}${DIM}         -  Escaneo nmap rapido${NC}"
echo -e "  ${DIM}${RED}nmap-all <IP>${NC}${DIM}      -  Escaneo completo automatizado${NC}"
echo -e "  ${DIM}${RED}netinfo${NC}${DIM}            -  Info completa de red${NC}"
echo ""
WELCOME

    chmod +x "$HOME_DIR/.config/autsecurity/welcome.sh"
    ok "Mensaje de bienvenida generado"
}

# ---------------------------------------------------------------------------
# SCREENSHOTS DIR
# ---------------------------------------------------------------------------
setup_screenshots() {
    mkdir -p "$HOME_DIR/Screenshots"
    ok "Directorio Screenshots creado"
}

# ---------------------------------------------------------------------------
# XINITRC / XSESSION
# ---------------------------------------------------------------------------
setup_xsession() {
    section "CONFIGURACION X SESSION"

    # .xinitrc
    cat > "$HOME_DIR/.xinitrc" << 'XINITRC'
#!/bin/sh
# AutSecurity Box - .xinitrc
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

[[ -f $sysresources  ]] && xrdb -merge $sysresources
[[ -f $sysmodmap     ]] && xmodmap $sysmodmap
[[ -f $userresources ]] && xrdb -merge $userresources
[[ -f $usermodmap    ]] && xmodmap $usermodmap

exec bspwm
XINITRC

    # .xsession (para display managers)
    cat > "$HOME_DIR/.xsession" << 'XSESSION'
#!/bin/sh
exec bspwm
XSESSION
    chmod +x "$HOME_DIR/.xsession"

    # Crear entrada de sesion para SDDM/GDM/LightDM
    sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Name=bspwm
Comment=AutSecurity Box - bspwm
Exec=/usr/bin/bspwm
TryExec=/usr/bin/bspwm
Type=Application
DESKTOP

    ok "X Session configurada"
}

# ---------------------------------------------------------------------------
# CONFIGURACION FINAL: GTK, CURSOR, ICONOS
# ---------------------------------------------------------------------------
setup_gtk_theme() {
    section "TEMA GTK Y VISUAL"

    # Instalar tema oscuro
    for pkg in gtk2-engines-murrine gtk2-engines-pixbuf papirus-icon-theme breeze-cursor-theme; do
        sudo apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1 || warn "Paquete opcional no disponible: $pkg"
    done

    # Descargar y aplicar tema GTK oscuro compatible
    if [[ ! -d "$HOME_DIR/.themes/Dracula" ]]; then
        step "Descargando tema Dracula GTK..."
        mkdir -p "$HOME_DIR/.themes"
        wget -q "https://github.com/dracula/gtk/archive/master.zip" -O /tmp/dracula-gtk.zip >> "$LOG_FILE" 2>&1
        unzip -q /tmp/dracula-gtk.zip -d /tmp/ >> "$LOG_FILE" 2>&1
        mv /tmp/gtk-master "$HOME_DIR/.themes/Dracula" 2>/dev/null
        ok "Tema Dracula GTK instalado"
    fi

    mkdir -p "$HOME_DIR/.config/gtk-3.0"
    cat > "$HOME_DIR/.config/gtk-3.0/settings.ini" << 'GTK3'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Hack Nerd Font 10
gtk-cursor-theme-name=Breeze_Snow
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_SMALL_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
GTK3

    cat > "$HOME_DIR/.gtkrc-2.0" << 'GTK2'
gtk-theme-name="Dracula"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Hack Nerd Font 10"
gtk-cursor-theme-name="Breeze_Snow"
gtk-cursor-theme-size=24
GTK2

    ok "Tema GTK configurado"
}

# ---------------------------------------------------------------------------
# GUARDAR MEMORIA DEL AGENTE
# ---------------------------------------------------------------------------
save_agent_memory() {
    section "MEMORIA DEL AGENTE"
    step "Guardando memoria del proyecto..."

    # Crear resumen de instalacion
    cat > "$HOME_DIR/.config/autsecurity/install_summary.txt" << SUMMARY
AutSecurity Box - Kali Linux Environment
Instalado: $(date '+%Y-%m-%d %H:%M:%S')
Usuario: $CURRENT_USER
Home: $HOME_DIR
Log: $LOG_FILE

Componentes instalados:
- WM: bspwm + sxhkd
- Terminal: Alacritty
- Shell: Zsh + Oh My Zsh + Powerlevel10k
- Compositor: Picom
- Barra: Polybar
- Launcher: Rofi
- Notificaciones: Dunst
- Fuentes: Hack Nerd Font, JetBrainsMono, FiraCode

Dotfiles en:
- ~/.config/bspwm/bspwmrc
- ~/.config/sxhkd/sxhkdrc
- ~/.config/alacritty/alacritty.toml
- ~/.config/picom/picom.conf
- ~/.config/polybar/config.ini
- ~/.config/rofi/themes/autsecurity.rasi
- ~/.config/dunst/dunstrc
- ~/.zshrc
- ~/.p10k.zsh
- ~/.aliases
SUMMARY

    ok "Resumen guardado en ~/.config/autsecurity/install_summary.txt"
}

# ---------------------------------------------------------------------------
# RESUMEN FINAL
# ---------------------------------------------------------------------------
final_summary() {
    section "INSTALACION COMPLETADA"
    echo ""
    log "${RED}  ╔══════════════════════════════════════════════════════╗${NC}"
    log "${RED}  ║    ${WHITE}AutSecurity Box - Instalacion Completada          ${RED}║${NC}"
    log "${RED}  ╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ $ERRORS -gt 0 ]]; then
        log "${ORANGE}  Instalacion completada con ${ERRORS} advertencias.${NC}"
        log "${ORANGE}  Revisa el log: $LOG_FILE${NC}"
    else
        log "${GREEN}  Instalacion exitosa sin errores.${NC}"
    fi

    echo ""
    log "${CYAN}  PROXIMOS PASOS:${NC}"
    log "  1. ${WHITE}Cierra sesion y vuelve a iniciar${NC} (necesario para Zsh y bspwm)"
    log "  2. En la pantalla de login selecciona ${WHITE}'bspwm'${NC} como sesion"
    log "  3. ${WHITE}Super + Return${NC} para abrir terminal"
    log "  4. ${WHITE}Super + d${NC} para lanzador de apps (Rofi)"
    log "  5. ${WHITE}Super + 1-9${NC} para cambiar workspaces"
    log "  6. Abre Burp Suite con ${WHITE}Super + b${NC}"
    echo ""
    log "${CYAN}  COMANDOS CTF RAPIDOS:${NC}"
    log "  ${RED}ctf-init <nombre-maquina>${NC}  - Crea estructura de directorios"
    log "  ${RED}target <IP>${NC}                - Configura IP objetivo"
    log "  ${RED}recon <IP>${NC}                 - Escaneo nmap inicial"
    log "  ${RED}nmap-all <IP>${NC}              - Escaneo completo automatizado"
    echo ""
    log "${DIM}  Log completo: $LOG_FILE${NC}"
    echo ""
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    banner

    log "Log de instalacion: $LOG_FILE"
    echo ""

    check_kali
    check_root
    check_internet
    check_disk_space

    echo ""
    log "${ORANGE}Este script instalara el entorno completo AutSecurity Box.${NC}"
    log "${ORANGE}Tiempo estimado: 20-40 minutos dependiendo de la conexion.${NC}"
    echo ""

    if ! ask_confirm "Iniciar instalacion?"; then
        log "Instalacion cancelada."
        exit 0
    fi

    update_system
    install_fonts
    install_wm
    install_alacritty
    install_shell
    install_fzf
    install_pentesting_tools
    generate_dotfiles
    setup_xsession
    setup_gtk_theme
    setup_screenshots
    setup_root_user
    save_agent_memory
    final_summary
}

# ---------------------------------------------------------------------------
# SETUP ROOT USER
# ---------------------------------------------------------------------------
setup_root_user() {
    step "Configurando entorno para usuario root..."

    # Oh-My-Zsh para root
    if [[ ! -d /root/.oh-my-zsh ]]; then
        sudo RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            >> "$LOG_FILE" 2>&1 \
            || warn "No se pudo instalar Oh-My-Zsh para root"
    fi

    # Symlink del directorio custom de kali a root
    # Esto hace que root comparta exactamente los mismos plugins y temas que kali
    # sin duplicar nada ni necesitar sincronizacion manual
    if [[ -d /root/.oh-my-zsh ]]; then
        if [[ -d /root/.oh-my-zsh/custom && ! -L /root/.oh-my-zsh/custom ]]; then
            sudo rm -rf /root/.oh-my-zsh/custom
        fi
        if [[ ! -L /root/.oh-my-zsh/custom ]]; then
            sudo ln -sf "$HOME_DIR/.oh-my-zsh/custom" /root/.oh-my-zsh/custom \
                && ok "Plugins/temas de kali enlazados a root via symlink"
        fi
    fi

    # Copiar dotfiles al home de root
    for dotfile in .zshrc .p10k.zsh .aliases .zshrc.pre-oh-my-zsh; do
        if [[ -f "$HOME_DIR/$dotfile" ]]; then
            sudo cp "$HOME_DIR/$dotfile" "/root/$dotfile"
        fi
    done

    # Ajustar rutas en .zshrc de root: /home/kali -> /root
    sudo sed -i "s|$HOME_DIR|/root|g" /root/.zshrc 2>/dev/null || true
    # Asegurar que ZSH apunta al oh-my-zsh de root
    sudo sed -i 's|^export ZSH=.*|export ZSH="/root/.oh-my-zsh"|' /root/.zshrc 2>/dev/null || true
    # Evitar warning de directorios inseguros al compartir custom/ via symlink
    sudo python3 -c "
import pathlib
f = pathlib.Path('/root/.zshrc')
lines = f.read_text().splitlines(keepends=True)
for i, line in enumerate(lines):
    if 'oh-my-zsh.sh' in line and line.strip().startswith('source'):
        if i == 0 or 'ZSH_DISABLE_COMPFIX' not in lines[i-1]:
            lines.insert(i, 'ZSH_DISABLE_COMPFIX=true\n')
        break
f.write_text(''.join(lines))
" 2>/dev/null || true
    # Corregir permisos del custom compartido para que compaudit no proteste
    sudo chmod -R g-w,o-w "$HOME_DIR/.oh-my-zsh/custom" 2>/dev/null || true

    # Symlink de .config/autsecurity para root
    sudo mkdir -p /root/.config
    if [[ -d "$HOME_DIR/.config/autsecurity" && ! -L /root/.config/autsecurity ]]; then
        sudo ln -sf "$HOME_DIR/.config/autsecurity" /root/.config/autsecurity
    fi

    # Cambiar shell de root a zsh
    if [[ "$(sudo getent passwd root | cut -d: -f7)" != "$(command -v zsh)" ]]; then
        sudo chsh -s "$(command -v zsh)" root >> "$LOG_FILE" 2>&1 \
            && ok "Shell de root cambiado a zsh" \
            || warn "No se pudo cambiar shell de root (hacerlo manualmente: sudo chsh -s $(command -v zsh) root)"
    fi

    ok "Entorno root configurado"
}

main "$@"
