<div align="center">

```
 █████╗ ██╗   ██╗████████╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
██╔══██╗██║   ██║╚══██╔══╝██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
███████║██║   ██║   ██║   ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝ 
██╔══██║██║   ██║   ██║   ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝  
██║  ██║╚██████╔╝   ██║   ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║   
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝  
                         ██████╗  ██████╗ ██╗  ██╗
                         ██╔══██╗██╔═══██╗╚██╗██╔╝
                         ██████╔╝██║   ██║ ╚███╔╝ 
                         ██╔══██╗██║   ██║ ██╔██╗ 
                         ██████╔╝╚██████╔╝██╔╝ ██╗
                         ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
```

### Entorno profesional de CTF & Pentesting para Kali Linux

[![Kali Linux](https://img.shields.io/badge/Kali_Linux-2024%2B-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![Shell Script](https://img.shields.io/badge/Shell_Script-bash-00ff88?style=for-the-badge&logo=gnu-bash&logoColor=black)](https://www.gnu.org/software/bash/)
[![bspwm](https://img.shields.io/badge/WM-bspwm-00ff88?style=for-the-badge&logoColor=white)](https://github.com/baskerville/bspwm)
[![License](https://img.shields.io/badge/License-MIT-00ff88?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0.0-0d0d1a?style=for-the-badge&labelColor=00ff88&color=0d0d1a)](https://github.com/autsecuritybox/autsecurity-kali-setup/releases)

</div>

---

## ¿Qué es AutSecurity Box?

**AutSecurity Box** es un script de instalación automática que transforma cualquier Kali Linux limpio en un entorno profesional de pentesting y CTF listo para usar. Con un solo comando configura un entorno visual completo, instala más de 40 herramientas de seguridad y optimiza cada detalle del flujo de trabajo ofensivo.

> **Instalación estimada:** 20-40 minutos · **Espacio requerido:** 10GB+

---

## Características principales

<table>
<tr>
<td width="50%">

**Entorno Visual**
- 🖥️ `bspwm` — Window manager de tiles
- 🎨 `Polybar` — Barra de estado con IP VPN, scope activo, CPU/RAM
- 🖱️ `Picom` — Compositor con sombras y transparencias
- 🚀 `Rofi` — Lanzador de aplicaciones con tema AutSecurity
- 🔔 `Dunst` — Notificaciones minimalistas
- 🐱 `Kitty` — Terminal con soporte nativo de tabs

</td>
<td width="50%">

**Shell y Productividad**
- ⚡ `Zsh` + `Oh My Zsh` + `Powerlevel10k`
- 🔍 `fzf` con integración zsh completa
- 📋 Clipboard dual (F1/F2 slot1 · F3/F4 slot2)
- 🎯 Sistema de scope integrado en Polybar
- 🗂️ Estructura de directorios CTF automática
- 🔑 5 Nerd Fonts (Hack, JetBrainsMono, FiraCode...)

</td>
</tr>
<tr>
<td>

**Herramientas de Reconocimiento**
- `nmap` · `masscan` · `nuclei` · `subfinder`
- `httpx` · `dnsx` · `katana` · `amass`
- `gobuster` · `ffuf` · `feroxbuster` · `nikto`
- `whatweb` · `wpscan` · `theharvester`

</td>
<td>

**Post-Explotación y AD**
- `metasploit-framework` · `bloodhound` · `neo4j`
- `evil-winrm` · `impacket` · `certipy-ad`
- `crackmapexec` → `netexec` · `kerbrute`
- `ligolo-ng` · `chisel` · `PEASS-ng` · `pspy64`

</td>
</tr>
</table>

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/autsecuritybox/autsecurity-kali-setup
cd autsecurity-kali-setup

# 2. Dar permisos de ejecución
chmod +x install.sh verify.sh

# 3. Ejecutar como usuario normal (NO como root)
./install.sh
```

> ⚠️ **Importante:** Ejecutar como usuario normal con sudo disponible. El script gestiona los permisos automáticamente.

### Verificación post-instalación

```bash
./verify.sh
```

Salida esperada:

```
  Pasadas: 52  Fallidas: 0  Avisos: 0
  Entorno listo. Reinicia sesión para activar todos los cambios.
```

### Activar el entorno

1. Cierra sesión y vuelve a iniciar
2. En la pantalla de login selecciona **`bspwm`** como sesión
3. `Super + Return` para abrir la terminal

---

## Atajos de teclado

### Terminal y aplicaciones

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir Kitty (reutiliza ventana existente con nueva tab) |
| `Super + Shift + Return` | Terminal flotante |
| `Super + D` | Rofi — lanzador de apps |
| `Super + B` | Burp Suite |
| `Super + W` | Firefox (workspace 2) |
| `Super + Shift + W` | Wireshark |
| `Super + E` | Thunar (gestor de archivos) |
| `Super + N` | Info de red rápida |
| `Super + Shift + L` | Bloquear pantalla |

### Kitty — Tabs

| Atajo | Acción |
|-------|--------|
| `Ctrl + Shift + T` | Nueva tab en el directorio actual |
| `Ctrl + Shift + Alt + T` | Renombrar tab activa |
| `Ctrl + Shift + ←/→` | Navegar entre tabs |
| `Ctrl + Shift + 1..0` | Ir directo a tab 1-10 |
| `Ctrl + Shift + W` | Cerrar tab |

### Clipboard dual

| Atajo | Acción |
|-------|--------|
| Seleccionar texto → `F1` | Copiar selección al slot 1 |
| `F2` | Pegar slot 1 |
| Seleccionar texto → `F3` | Copiar selección al slot 2 |
| `F4` | Pegar slot 2 |

### Workspaces y ventanas

| Atajo | Acción |
|-------|--------|
| `Super + 1-9` | Cambiar workspace |
| `Super + Shift + 1-9` | Mover ventana a workspace |
| `Super + H/J/K/L` | Mover foco (vim-style) |
| `Super + Shift + H/J/K/L` | Mover ventana |
| `Super + Alt + Flechas` | Expandir ventana |
| `Super + Alt + Shift + Flechas` | Contraer ventana |
| `Super + F` | Fullscreen toggle |
| `Super + Shift + Space` | Floating toggle |
| `Super + G` | Swap con ventana más grande |
| `Super + M` | Monocle layout |

### Pentesting — IPs rápidas

| Atajo | Acción |
|-------|--------|
| `Super + Shift + F1` | Copiar IP local al clipboard + notificación |
| `Super + Shift + F2` | Copiar IP VPN (tun0) al clipboard + notificación |
| `Super + Shift + F3` | Copiar target actual al clipboard + notificación |

### Capturas de pantalla

| Atajo | Acción |
|-------|--------|
| `Print` | Captura completa → `~/Screenshots/` |
| `Super + Print` | Selección interactiva (Flameshot) |
| `Super + Shift + Print` | Ventana activa → clipboard |

---

## Comandos CTF

```bash
# Crear estructura de trabajo para una máquina
ctf-init <nombre-maquina>
# Genera: ~/ctf/<nombre>/{recon,exploit,post,files,notes}

# Definir IP objetivo (persiste en polybar)
target 10.10.10.1

# Escaneo rápido
recon 10.10.10.1

# Escaneo completo automatizado
nmap-all 10.10.10.1

# Extraer puertos de salida nmap grepable
extract-ports nmap/scan.gnmap

# Gestionar scope
scope add 10.10.10.1 example.com
scope list
scope remove 10.10.10.1
scope clear

# Copiar contenido de archivo al clipboard
xcopy output.txt

# Info de red completa
netinfo
```

---

## Polybar — Módulos

| Módulo | Descripción |
|--------|-------------|
| `Workspaces` | Indicador de workspaces bspwm con color activo |
| `Scope` | Número de targets activos (`󰞇 Scope (3)`) |
| `VPN` | IP de `tun0` en tiempo real |
| `IP Local` | IP de interfaz principal |
| `CPU %` | Uso del procesador |
| `RAM %` | Uso de memoria |
| `Disco %` | Uso de `/` |
| `Volumen` | Control PulseAudio |
| `Fecha/Hora` | Reloj en tiempo real |

---

## Estructura generada

```
~/
├── ctf/                    # Entornos de trabajo CTF
├── tools/
│   ├── pspy64              # Monitor de procesos sin root
│   ├── ligolo-ng/          # Proxy para tunneling
│   ├── PEASS-ng/           # linPEAS + winPEAS
│   └── PowerSploit/        # Post-explotación PS
├── Screenshots/            # Capturas de pantalla
└── .config/
    ├── bspwm/bspwmrc
    ├── sxhkd/sxhkdrc
    ├── kitty/kitty.conf
    ├── polybar/
    ├── rofi/themes/autsecurity.rasi
    ├── picom/picom.conf
    ├── dunst/dunstrc
    └── autsecurity/
        └── welcome.sh      # Mensaje de bienvenida con info de red
```

---

## Requisitos

- Kali Linux 2024+ (Rolling)
- Usuario normal con `sudo` disponible
- Conexión a internet
- 10GB de espacio libre en disco
- Entorno gráfico X11

---

## Actualizaciones

Este proyecto es mantenido personalmente por **[@autsecuritybox](https://github.com/autsecuritybox)**. Las mejoras, nuevas herramientas y correcciones se publican directamente en este repositorio.

Para estar al tanto de cada actualización:

- ⭐ **Star** al repositorio para apoyar el proyecto
- 👁️ **Watch → All Activity** para recibir notificaciones de cada release
- 🔔 Sígueme en GitHub para ver todos los proyectos nuevos

Si encuentras un bug o tienes una sugerencia, abre un [issue](https://github.com/autsecuritybox/autsecurity-kali-setup/issues) y lo revisaré personalmente.

---

## Inspiración

Este proyecto integra lo mejor de varios entornos de la comunidad:

- [AutoBspwmKali](https://github.com/Justice-Reaper/AutoBspwmKali) — Justice Reaper
- [bspwm-config](https://github.com/gh0stzk/dotfiles) — gh0stzk
- Comunidad de Hack The Box y TryHackMe

---

<div align="center">

**Hecho con 🖤 para la comunidad hacker hispanohablante**

[![GitHub](https://img.shields.io/badge/GitHub-autsecuritybox-00ff88?style=for-the-badge&logo=github&logoColor=white)](https://github.com/autsecuritybox)

</div>
