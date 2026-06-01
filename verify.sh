#!/usr/bin/env bash
# =============================================================================
# AutSecurity Box - Script de Verificacion Post-Instalacion
# =============================================================================

RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

ok()   { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "${ORANGE}[WARN]${NC} $1"; WARN=$((WARN+1)); }
hdr()  { echo -e "\n${CYAN}--- $1 ---${NC}"; }

check_cmd() {
    local cmd="$1"
    local label="${2:-$cmd}"
    command -v "$cmd" &>/dev/null && ok "$label" || fail "$label no encontrado"
}

check_file() {
    local f="$1"
    [[ -f "$f" ]] && ok "$f" || fail "Archivo faltante: $f"
}

check_dir() {
    local d="$1"
    [[ -d "$d" ]] && ok "$d" || fail "Directorio faltante: $d"
}

echo ""
echo -e "${RED}╔══════════════════════════════════════╗${NC}"
echo -e "${RED}║  AutSecurity Box - Verificacion      ║${NC}"
echo -e "${RED}╚══════════════════════════════════════╝${NC}"
echo ""

hdr "WINDOW MANAGER"
check_cmd bspwm
check_cmd sxhkd
check_cmd picom
check_cmd polybar
check_cmd rofi
check_cmd dunst

hdr "TERMINAL Y SHELL"
check_cmd alacritty
check_cmd zsh
check_dir "$HOME/.oh-my-zsh"
check_dir "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
check_cmd fzf

hdr "DOTFILES"
check_file "$HOME/.config/bspwm/bspwmrc"
check_file "$HOME/.config/sxhkd/sxhkdrc"
check_file "$HOME/.config/alacritty/alacritty.toml"
check_file "$HOME/.config/picom/picom.conf"
check_file "$HOME/.config/polybar/config.ini"
check_file "$HOME/.config/polybar/launch.sh"
check_file "$HOME/.config/rofi/themes/autsecurity.rasi"
check_file "$HOME/.config/dunst/dunstrc"
check_file "$HOME/.zshrc"
check_file "$HOME/.p10k.zsh"
check_file "$HOME/.aliases"
check_file "$HOME/.config/autsecurity/welcome.sh"

hdr "FUENTES NERD FONTS"
fc-list | grep -qi "hack nerd" && ok "Hack Nerd Font" || warn "Hack Nerd Font no detectada"
fc-list | grep -qi "jetbrains" && ok "JetBrainsMono Nerd Font" || warn "JetBrainsMono no detectada"

hdr "HERRAMIENTAS DE PENTESTING"
check_cmd nmap
check_cmd masscan
check_cmd gobuster
check_cmd ffuf
check_cmd feroxbuster
check_cmd sqlmap
check_cmd nikto
check_cmd whatweb
check_cmd hydra
check_cmd john
check_cmd hashcat
check_cmd chisel
check_cmd msfconsole
check_cmd bloodhound
check_cmd evil-winrm

hdr "HERRAMIENTAS GO"
check_cmd nuclei
check_cmd subfinder
check_cmd httpx
check_cmd kerbrute

hdr "DIRECTORIOS DE HERRAMIENTAS"
check_dir "$HOME/tools"
[[ -f "$HOME/tools/pspy64" ]] && ok "pspy64" || warn "pspy64 no descargado"
check_dir "$HOME/tools/PEASS-ng" 2>/dev/null || warn "PEASS-ng no clonado"
[[ -d "$HOME/tools/ligolo-ng" ]] && ok "ligolo-ng" || warn "ligolo-ng no instalado"

hdr "WORDLISTS"
[[ -d /usr/share/seclists ]] && ok "SecLists en /usr/share/seclists" || warn "SecLists no instalado"
[[ -f /usr/share/wordlists/rockyou.txt ]] && ok "rockyou.txt" || warn "rockyou.txt no encontrado"

hdr "RED"
LOCAL_IP=$(ip -4 addr show scope global 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo -e "  IP Local: ${WHITE}${LOCAL_IP:-sin red}${NC}"
echo -e "  VPN (tun0): ${VPN_IP:-desconectada}"

echo ""
echo -e "${RED}═══════════════════════════════════════${NC}"
echo -e "  Pasadas: ${GREEN}$PASS${NC}  Fallidas: ${RED}$FAIL${NC}  Avisos: ${ORANGE}$WARN${NC}"
echo -e "${RED}═══════════════════════════════════════${NC}"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${ORANGE}Ejecuta install.sh para corregir los items fallidos.${NC}"
else
    echo -e "${GREEN}Entorno listo. Reinicia sesion para activar todos los cambios.${NC}"
fi
echo ""
