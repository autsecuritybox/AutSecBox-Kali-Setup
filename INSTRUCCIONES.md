# AutSecurity Box - Kali Linux Environment Setup

## Uso rapido

```bash
git clone https://github.com/tu-usuario/autsecurity-kali-setup
cd autsecurity-kali-setup
chmod +x install.sh verify.sh
./install.sh
```

## Lo que instala

### Entorno grafico
| Componente     | Herramienta              |
|----------------|--------------------------|
| Window Manager | bspwm + sxhkd            |
| Terminal       | Alacritty                |
| Compositor     | Picom (blur + sombras)   |
| Barra estado   | Polybar                  |
| Launcher       | Rofi                     |
| Notificaciones | Dunst                    |
| Shell          | Zsh + Oh My Zsh + P10k   |
| Fuentes        | Hack Nerd Font (+ otras) |

### Atajos clave (sxhkd)
| Atajo                  | Accion                         |
|------------------------|--------------------------------|
| Super + Return         | Abrir terminal                 |
| Super + Shift + Return | Terminal flotante              |
| Super + d              | Rofi launcher                  |
| Super + 1-9            | Cambiar workspace              |
| Super + Shift + 1-9    | Mover ventana a workspace      |
| Super + h/j/k/l        | Mover foco (vim)               |
| Super + Shift + q      | Cerrar ventana                 |
| Super + f              | Fullscreen toggle              |
| Super + Shift + Space  | Floating toggle                |
| Print                  | Captura pantalla completa      |
| Super + Print          | Captura interactiva (Flameshot)|
| Super + b              | Burp Suite                     |
| Super + w              | Firefox (workspace 2)          |
| Super + n              | Info de red rapida             |
| Super + Escape         | Recargar sxhkd                 |

### Workspaces sugeridos
```
1  - Terminal / general
2  - Navegador web (Firefox)
3  - Burp Suite
4  - Wireshark / analisis de red
5  - VMs
6-9 - Libre
```

### Polybar modulos
- Workspaces bspwm
- Titulo ventana activa
- IP local (auto-detectada)
- IP VPN (tun0)
- CPU %
- RAM %
- Disco %
- Volumen
- Fecha y hora

### Aliases importantes (.aliases)
```bash
# Crear entorno de trabajo para maquina CTF
ctf-init <nombre-maquina>

# Configurar target
target <IP>

# Escaneo rapido
recon <IP>

# Escaneo completo automatizado
nmap-all <IP>

# Ver info de red
netinfo

# Nmap shortcuts
nmap-quick, nmap-full, nmap-udp, nmap-vuln, nmap-stealth

# Gobuster/ffuf con wordlists preconfiguradas
gobuster-dir <URL>
ffuf-dir <URL>/FUZZ
ferox <URL>

# BloodHound
bloodhound-start
```

### Herramientas en ~/tools/
```
~/tools/
├── pspy64              # Monitor de procesos sin root
├── ligolo-ng/          # proxy + agent para tunneling
├── PEASS-ng/           # linPEAS + winPEAS
├── enum4linux-ng/      # Enumeracion SMB/LDAP
└── PowerSploit/        # PowerShell post-explotacion
```

## Verificacion post-instalacion
```bash
./verify.sh
```

## Notas importantes

1. Ejecutar como usuario normal (no root), sudo se pide automaticamente
2. Se requiere reiniciar sesion despues de la instalacion
3. En el login, seleccionar "bspwm" como sesion
4. El script es idempotente: puede ejecutarse varias veces
5. Log de instalacion en /tmp/autsecurity_install_*.log

## Estructura de directorios generados
```
~/.config/
├── bspwm/bspwmrc
├── sxhkd/sxhkdrc
├── alacritty/alacritty.toml
├── picom/picom.conf
├── polybar/
│   ├── config.ini
│   ├── launch.sh
│   └── scripts/
│       ├── vpn.sh
│       ├── localip.sh
│       └── net-info.sh
├── rofi/themes/autsecurity.rasi
├── dunst/dunstrc
├── gtk-3.0/settings.ini
└── autsecurity/
    ├── welcome.sh
    └── install_summary.txt

~/.zshrc
~/.p10k.zsh
~/.aliases
~/.local/share/wallpapers/autsecurity.png
~/Screenshots/
~/tools/
~/go/bin/   (herramientas Go)
```
